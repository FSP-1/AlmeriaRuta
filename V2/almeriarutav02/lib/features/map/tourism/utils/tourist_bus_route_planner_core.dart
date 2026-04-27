import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/services/line_models.dart';
import '../models/tourist_place.dart';
import 'tourist_bus_route_planner_helpers.dart';
import 'tourist_bus_route_planner_models.dart';

// ─── Internal DP node ────────────────────────────────────────────────────────
// Each node represents arriving at a stop via a specific line.
// boardingStopId = the stop where the user boarded this line leg.
// This lets reconstruction extract ALL intermediate stops from the real sequence.

class _Node {
  final String stopId;
  final double costMinutes;
  final double walkMeters;       // walk distance to the very first boarding stop
  final _Node? prev;
  final LineModel? lineUsed;
  final String? boardingStopId;  // where this bus leg started
  final bool reversed;           // which direction of the line sequence was used
  final int indexInLine;         // current index in the active line direction sequence
  final int busStopsTaken;       // total count of bus hops taken so far
  final int legStopsRidden;      // stops ridden in the current line leg
  final int transfers;

  const _Node({
    required this.stopId,
    required this.costMinutes,
    required this.walkMeters,
    this.prev,
    this.lineUsed,
    this.boardingStopId,
    this.reversed = false,
    this.indexInLine = -1,
    this.busStopsTaken = 0,
    this.legStopsRidden = 0,
    this.transfers = 0,
  });
}

class _LineDirection {
  final LineModel line;
  final bool reversed;
  final List<StopModel> sequence;

  const _LineDirection({
    required this.line,
    required this.reversed,
    required this.sequence,
  });
}

class _StopOccurrence {
  final _LineDirection direction;
  final int index;

  const _StopOccurrence({
    required this.direction,
    required this.index,
  });
}

// ─── Main planner ─────────────────────────────────────────────────────────────

class TouristBusRoutePlanner {

  static TouristBusRoutePlan? buildPlan({
    required TouristPlace place,
    required LatLng userLocation,
    required StopModel destinationStop,
    required List<LineModel> allLines,
    double maxWalkToBoardMeters = 1200,
    int maxTransfers = 1,
    int minBusLegStopsBeforeTransfer = 2,
    int minSavingMinutes = 2,
  }) {
    // Index stops by id for fast lookup
    final stopById = <String, StopModel>{};
    for (final line in allLines) {
      for (final stop in line.stops) {
        stopById[stop.id] = stop;
      }
    }

    // Precompute directed line sequences and stop occurrences to avoid
    // expensive index lookups on every explored node.
    final stopOccurrences = <String, List<_StopOccurrence>>{};
    for (final line in allLines) {
      if (line.stops.length < 2) continue;

      final forward = _LineDirection(
        line: line,
        reversed: false,
        sequence: line.stops,
      );
      final backward = _LineDirection(
        line: line,
        reversed: true,
        sequence: line.stops.reversed.toList(),
      );
      for (final direction in [forward, backward]) {
        for (var idx = 0; idx < direction.sequence.length; idx++) {
          final stopId = direction.sequence[idx].id;
          stopOccurrences
              .putIfAbsent(stopId, () => <_StopOccurrence>[])
              .add(_StopOccurrence(direction: direction, index: idx));
        }
      }
    }

    final directWalkMeters = Geolocator.distanceBetween(
      userLocation.latitude, userLocation.longitude,
      place.location.latitude, place.location.longitude,
    );
    final directWalkMinutes = estimateWalkingMinutes(directWalkMeters).toDouble();

    // For far places, allow a bit more initial walking to reach a useful line.
    final effectiveMaxWalkToBoardMeters = maxWalkToBoardMeters
        .clamp(0, (directWalkMeters * 0.55).clamp(1200, 2200));

    // Best-known cost per transit state: (stop, current line, transfers).
    final distByState = <String, double>{};
    final queue = SplayTreeMap<double, Queue<_Node>>();

    String stateKey(_Node node) {
      final lineId = node.lineUsed?.id ?? 'walk';
      final dir = node.reversed ? 'rev' : 'fwd';
      final transferReady = node.legStopsRidden >= minBusLegStopsBeforeTransfer ? 1 : 0;
      return '${node.stopId}|$lineId|$dir|${node.indexInLine}|${node.transfers}|$transferReady';
    }

    void enqueue(_Node node) {
      final key = stateKey(node);
      if (node.costMinutes >= (distByState[key] ?? double.infinity)) return;
      distByState[key] = node.costMinutes;
      queue.putIfAbsent(node.costMinutes, Queue.new).add(node);
    }

    // Seed: all stops reachable on foot from user
    for (final line in allLines) {
      for (final stop in line.stops) {
        final walkM = Geolocator.distanceBetween(
          userLocation.latitude, userLocation.longitude,
          stop.lat, stop.lon,
        );
        if (walkM > effectiveMaxWalkToBoardMeters) continue;
        final walkMin = estimateWalkingMinutes(walkM).toDouble();
        enqueue(_Node(
          stopId: stop.id,
          costMinutes: walkMin,
          walkMeters: walkM,
          lineUsed: null,
          boardingStopId: null,
          indexInLine: -1,
          busStopsTaken: 0,
          legStopsRidden: 0,
          transfers: 0,
        ));
      }
    }

    _Node? destinationNode;

    while (queue.isNotEmpty) {
      final minKey = queue.firstKey()!;
      final bucket = queue[minKey]!;
      final current = bucket.removeFirst();
      if (bucket.isEmpty) queue.remove(minKey);

      // Stale entry
      if (current.costMinutes > (distByState[stateKey(current)] ?? double.infinity)) continue;

      if (current.stopId == destinationStop.id) {
        if (current.busStopsTaken == 0) continue;
        destinationNode = current;
        break;
      }

      final currentStop = stopById[current.stopId];
      if (currentStop == null) continue;

      final occurrences = stopOccurrences[current.stopId];
      if (occurrences == null || occurrences.isEmpty) continue;

      for (final occurrence in occurrences) {
        final direction = occurrence.direction;
        final boardIdx = occurrence.index;
        final sequence = direction.sequence;
        if (boardIdx >= sequence.length - 1) continue;

        final nextIdx = boardIdx + 1;
        final nextStop = sequence[nextIdx];
        const busHopMinutes = 2.0;

        // Continue on the current bus line only by advancing to the next stop.
        final sameLine = current.lineUsed?.id == direction.line.id;
        final sameDirection = current.reversed == direction.reversed;
        final canContinueCurrentLeg =
            current.lineUsed != null &&
            sameLine &&
            sameDirection &&
            current.indexInLine == boardIdx;

        if (canContinueCurrentLeg) {
          final newCost = current.costMinutes + busHopMinutes;
          enqueue(_Node(
            stopId: nextStop.id,
            costMinutes: newCost,
            walkMeters: current.walkMeters,
            prev: current,
            lineUsed: direction.line,
            boardingStopId: current.boardingStopId,
            reversed: direction.reversed,
            indexInLine: nextIdx,
            busStopsTaken: current.busStopsTaken + 1,
            legStopsRidden: current.legStopsRidden + 1,
            transfers: current.transfers,
          ));
          continue;
        }

        // Boarding from walking state.
        if (current.lineUsed == null) {
          final newCost = current.costMinutes + busHopMinutes;
          enqueue(_Node(
            stopId: nextStop.id,
            costMinutes: newCost,
            walkMeters: current.walkMeters,
            prev: current,
            lineUsed: direction.line,
            boardingStopId: current.stopId,
            reversed: direction.reversed,
            indexInLine: nextIdx,
            busStopsTaken: current.busStopsTaken + 1,
            legStopsRidden: 1,
            transfers: current.transfers,
          ));
          continue;
        }

        // Transfer only to a different line, with a realistic penalty.
        if (!sameLine &&
            current.transfers < maxTransfers &&
            current.legStopsRidden >= minBusLegStopsBeforeTransfer) {
          final newTransfers = current.transfers + 1;
          final transferPenalty = 6.0;
          final newCost = current.costMinutes + transferPenalty + busHopMinutes;
          enqueue(_Node(
            stopId: nextStop.id,
            costMinutes: newCost,
            walkMeters: current.walkMeters,
            prev: current,
            lineUsed: direction.line,
            boardingStopId: current.stopId,
            reversed: direction.reversed,
            indexInLine: nextIdx,
            busStopsTaken: current.busStopsTaken + 1,
            legStopsRidden: 1,
            transfers: newTransfers,
          ));
        }
      }
    }

    if (destinationNode == null) return null;

    final walkFromStopMeters = Geolocator.distanceBetween(
      destinationStop.lat, destinationStop.lon,
      place.location.latitude, place.location.longitude,
    );
    final walkFromStopMinutes = estimateWalkingMinutes(walkFromStopMeters);
    final totalMinutes = destinationNode.costMinutes.round() + walkFromStopMinutes;

    if ((directWalkMinutes - totalMinutes) < minSavingMinutes) return null;

    // Reconstruct segments with ALL intermediate stops from the real line sequence
    final segments = _reconstructSegments(destinationNode, stopById, allLines);
    if (segments.isEmpty) return null;

    final allRouteStops = <StopModel>[];
    for (var i = 0; i < segments.length; i++) {
      allRouteStops.addAll(
        i == 0 ? segments[i].routeStops : segments[i].routeStops.skip(1),
      );
    }

    final walkToBoardMeters = destinationNode.walkMeters;
    final walkToBoardMinutes = estimateWalkingMinutes(walkToBoardMeters);
    final busRideMinutes = totalMinutes - walkToBoardMinutes - walkFromStopMinutes;

    assert(() {
      final segmentSizes = segments.map((s) => s.routeStops.length).join(',');
      final stopNames = allRouteStops.map((s) => s.name).join(' -> ');
      debugPrint('[TouristBusRoutePlanner] place=${place.name} destStop=${destinationStop.name} '
          'segments=${segments.length} segmentStops=[$segmentSizes] totalStops=${allRouteStops.length}');
      debugPrint('[TouristBusRoutePlanner] routeStops=$stopNames');
      return true;
    }());

    return TouristBusRoutePlan(
      place: place,
      destinationStop: destinationStop,
      line: segments.first.line,
      boardingStop: segments.first.boardingStop,
      segments: segments,
      routeStops: allRouteStops,
      routePoints: [
        userLocation,
        ...allRouteStops.map((s) => LatLng(s.lat, s.lon)),
        place.location,
      ],
      walkToBoardMeters: walkToBoardMeters,
      walkToBoardMinutes: walkToBoardMinutes,
      walkFromStopToPlaceMeters: walkFromStopMeters,
      walkFromStopToPlaceMinutes: walkFromStopMinutes,
      busRideMinutes: busRideMinutes.clamp(0, 999),
      totalDistanceMeters: walkToBoardMeters +
          walkFromStopMeters +
          calculateSegmentDistance(allRouteStops),
      totalDurationMinutes: totalMinutes,
    );
  }

  // ── Reconstruct segments with full intermediate stops ─────────────────────
  //
  // The DP back-pointer chain only stores (boardingStopId → arrivalStopId).
  // To get ALL intermediate stops we look up the real line sequence and
  // extract the slice from boardingStopId to arrivalStopId.

  static List<TouristBusSegment> _reconstructSegments(
    _Node destinationNode,
    Map<String, StopModel> stopById,
    List<LineModel> allLines,
  ) {
    final lineById = {for (final line in allLines) line.id: line};

    // Reconstruct full path from destination back to the origin.
    final path = <_Node>[];
    _Node? node = destinationNode;
    while (node != null) {
      path.add(node);
      node = node.prev;
    }
    final nodes = path.reversed.toList();

    final segments = <TouristBusSegment>[];
    var i = 0;
    while (i < nodes.length) {
      final current = nodes[i];

      // Skip non-bus nodes.
      if (current.lineUsed == null || current.boardingStopId == null) {
        i++;
        continue;
      }

      final line = lineById[current.lineUsed!.id];
      if (line == null) {
        i++;
        continue;
      }

      final boardingStopId = current.boardingStopId!;
      final reversed = current.reversed;

      // Group all consecutive nodes that belong to the same bus leg.
      var j = i;
      while (
        j + 1 < nodes.length &&
        nodes[j + 1].lineUsed?.id == current.lineUsed!.id &&
        nodes[j + 1].boardingStopId == boardingStopId
      ) {
        j++;
      }

      final arrivalStopId = nodes[j].stopId;
      final sequence = reversed
          ? line.stops.reversed.toList()
          : line.stops;

      final fromIdx = sequence.indexWhere((s) => s.id == boardingStopId);
      final toIdx = sequence.indexWhere((s) => s.id == arrivalStopId);

      if (fromIdx == -1 || toIdx == -1) {
        i = j + 1;
        continue;
      }

        final directionalStops = fromIdx <= toIdx
          ? sequence.sublist(fromIdx, toIdx + 1)
          : sequence.sublist(toIdx, fromIdx + 1).reversed.toList();

        final routeStops = directionalStops
          .map((s) => stopById[s.id] ?? s)
          .toList();

      if (routeStops.length >= 2) {
        segments.add(TouristBusSegment(
          line: line,
          boardingStop: routeStops.first,
          destinationStop: routeStops.last,
          routeStops: routeStops,
        ));
      }

      i = j + 1;
    }

    return segments;
  }

  // ── Nearby stops ──────────────────────────────────────────────────────────

  static List<TouristNearbyStopOption> findNearbyStops({
    required TouristPlace place,
    required List<StopModel> allStops,
    required List<LineModel> allLines,
    LatLng? userLocation,
    double maxDistanceMeters = 650,
    double maxWalkToBoardMeters = double.infinity,
    int limit = 8,
  }) {
    final options = <TouristNearbyStopOption>[];

    for (final stop in allStops) {
      final distanceToPlace = Geolocator.distanceBetween(
        place.location.latitude, place.location.longitude,
        stop.lat, stop.lon,
      );
      if (distanceToPlace > maxDistanceMeters) continue;

      final servingLines = allLines
          .where((line) => stop.lineIds.contains(line.id))
          .toList();

      double? walkFromUserToBoardMeters;
      var filteredServingLines = servingLines;

      if (userLocation != null) {
        filteredServingLines = <LineModel>[];
        double? bestWalk;

        for (final line in servingLines) {
          final plan = buildPlan(
            place: place,
            userLocation: userLocation,
            destinationStop: stop,
            allLines: [line],
            maxWalkToBoardMeters:
                maxWalkToBoardMeters.isInfinite ? 1200 : maxWalkToBoardMeters,
            minSavingMinutes: 0,
          );
          if (plan == null) continue;
          filteredServingLines.add(line);
          if (bestWalk == null || plan.walkToBoardMeters < bestWalk) {
            bestWalk = plan.walkToBoardMeters;
          }
        }

        if (filteredServingLines.isEmpty) filteredServingLines = servingLines;
        walkFromUserToBoardMeters = bestWalk;
      }

      options.add(TouristNearbyStopOption(
        stop: stop,
        distanceToPlaceMeters: distanceToPlace,
        servingLines: filteredServingLines,
        walkFromUserToBoardMeters: walkFromUserToBoardMeters,
      ));
    }

    options.sort((a, b) {
      if (a.walkFromUserToBoardMeters != null &&
          b.walkFromUserToBoardMeters != null) {
        final d = a.walkFromUserToBoardMeters!
            .compareTo(b.walkFromUserToBoardMeters!);
        if (d != 0) return d;
      }
      return a.distanceToPlaceMeters.compareTo(b.distanceToPlaceMeters);
    });

    return options.length <= limit ? options : options.take(limit).toList();
  }

}
