import 'dart:collection';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/services/line_models.dart';
import '../models/tourist_place.dart';
import 'tourist_bus_route_planner_helpers.dart';
import 'tourist_bus_route_planner_models.dart';

// ─── Internal DP node ────────────────────────────────────────────────────────

class _Node {
  final String stopId;
  final double costMinutes;   // accumulated time so far
  final double walkMeters;    // walk to first boarding stop
  final _Node? prev;
  final LineModel? lineUsed;  // line taken to arrive at this node
  final int transfers;        // number of line changes so far

  const _Node({
    required this.stopId,
    required this.costMinutes,
    required this.walkMeters,
    this.prev,
    this.lineUsed,
    this.transfers = 0,
  });
}

// ─── Main planner ─────────────────────────────────────────────────────────────

class TouristBusRoutePlanner {

  /// Dijkstra-based planner.
  ///
  /// Nodes = bus stops reachable from [userLocation].
  /// Edges = bus legs along real stop sequences (all intermediate stops included).
  /// Cost  = walk_to_board_minutes + bus_ride_minutes + transfer_penalty.
  ///
  /// Returns null if no bus route saves at least [minSavingMinutes] vs walking.
  static TouristBusRoutePlan? buildPlan({
    required TouristPlace place,
    required LatLng userLocation,
    required StopModel destinationStop,
    required List<LineModel> allLines,
    double maxWalkToBoardMeters = 1200,
    int maxTransfers = 1,
    int minSavingMinutes = 5,
  }) {
    // Build stop index for fast lookup
    final stopById = <String, StopModel>{};
    for (final line in allLines) {
      for (final stop in line.stops) {
        stopById[stop.id] = stop;
      }
    }

    // Direct walk time as baseline
    final directWalkMeters = Geolocator.distanceBetween(
      userLocation.latitude, userLocation.longitude,
      place.location.latitude, place.location.longitude,
    );
    final directWalkMinutes = estimateWalkingMinutes(directWalkMeters).toDouble();

    // ── Dijkstra ──────────────────────────────────────────────────────────────
    // Priority queue ordered by costMinutes (min-heap via SplayTreeMap)
    final dist = <String, double>{};          // stopId → best cost so far
    final best = <String, _Node>{};           // stopId → best node
    final queue = SplayTreeMap<double, Queue<_Node>>();

    void enqueue(_Node node) {
      final key = node.costMinutes;
      queue.putIfAbsent(key, Queue.new).add(node);
      if ((dist[node.stopId] ?? double.infinity) > node.costMinutes) {
        dist[node.stopId] = node.costMinutes;
        best[node.stopId] = node;
      }
    }

    // Seed: all stops reachable on foot from user within maxWalkToBoardMeters
    for (final line in allLines) {
      for (final stop in line.stops) {
        final walkM = Geolocator.distanceBetween(
          userLocation.latitude, userLocation.longitude,
          stop.lat, stop.lon,
        );
        if (walkM > maxWalkToBoardMeters) continue;

        final walkMin = estimateWalkingMinutes(walkM).toDouble();
        final node = _Node(
          stopId: stop.id,
          costMinutes: walkMin,
          walkMeters: walkM,
          lineUsed: null,
          transfers: 0,
        );
        if (walkMin < (dist[stop.id] ?? double.infinity)) {
          enqueue(node);
        }
      }
    }

    _Node? destinationNode;

    while (queue.isNotEmpty) {
      final minKey = queue.firstKey()!;
      final bucket = queue[minKey]!;
      final current = bucket.removeFirst();
      if (bucket.isEmpty) queue.remove(minKey);

      // Skip stale entries
      if (current.costMinutes > (dist[current.stopId] ?? double.infinity)) continue;

      // Reached destination stop
      if (current.stopId == destinationStop.id) {
        destinationNode = current;
        break;
      }

      if (current.transfers >= maxTransfers && current.lineUsed != null) continue;

      // Expand: for each line passing through this stop, ride forward
      // along the real stop sequence to every reachable stop.
      final currentStop = stopById[current.stopId];
      if (currentStop == null) continue;

      for (final line in allLines) {
        if (line.stops.isEmpty) continue;

        // Try both directions of the line
        for (final sequence in [line.stops, line.stops.reversed.toList()]) {
          final boardIdx = sequence.indexWhere((s) => s.id == current.stopId);
          if (boardIdx < 0 || boardIdx == sequence.length - 1) continue;

          final isTransfer = current.lineUsed != null && current.lineUsed!.id != line.id;
          if (isTransfer && current.transfers >= maxTransfers) continue;

          final newTransfers = current.transfers + (isTransfer ? 1 : 0);
          final transferPenalty = isTransfer ? 8.0 : 0.0;

          // Ride forward stop by stop — each stop is a candidate node
          for (var i = boardIdx + 1; i < sequence.length; i++) {
            final nextStop = sequence[i];
            final stopsRidden = i - boardIdx; // number of stops on bus
            final busMin = estimateBusRideMinutes(stopsRidden + 1).toDouble();

            // Detour guard: route distance vs straight line from boarding to here
            final segment = sequence.sublist(boardIdx, i + 1);
            final routeDist = _distanceAlongStops(segment);
            final straightDist = Geolocator.distanceBetween(
              currentStop.lat, currentStop.lon,
              nextStop.lat, nextStop.lon,
            );
            if (straightDist > 0 && routeDist / straightDist > 2.5) break;

            final newCost = current.costMinutes + busMin + transferPenalty;
            if (newCost >= (dist[nextStop.id] ?? double.infinity)) continue;

            enqueue(_Node(
              stopId: nextStop.id,
              costMinutes: newCost,
              walkMeters: current.walkMeters,
              prev: current,
              lineUsed: line,
              transfers: newTransfers,
            ));
          }
        }
      }
    }

    if (destinationNode == null) return null;

    // Walk from destination stop to the place
    final walkFromStopMeters = Geolocator.distanceBetween(
      destinationStop.lat, destinationStop.lon,
      place.location.latitude, place.location.longitude,
    );
    final walkFromStopMinutes = estimateWalkingMinutes(walkFromStopMeters);
    final totalMinutes = destinationNode.costMinutes.round() + walkFromStopMinutes;

    // Reject if bus doesn't save enough vs walking directly
    if ((directWalkMinutes - totalMinutes) < minSavingMinutes) return null;

    // ── Reconstruct path ──────────────────────────────────────────────────────
    final segments = _reconstructSegments(destinationNode, stopById);
    if (segments.isEmpty) return null;

    final allRouteStops = <StopModel>[];
    for (var i = 0; i < segments.length; i++) {
      if (i == 0) {
        allRouteStops.addAll(segments[i].routeStops);
      } else {
        allRouteStops.addAll(segments[i].routeStops.skip(1));
      }
    }

    final routePoints = <LatLng>[
      userLocation,
      ...allRouteStops.map((s) => LatLng(s.lat, s.lon)),
      place.location,
    ];

    final walkToBoardMeters = destinationNode.walkMeters;
    final walkToBoardMinutes = estimateWalkingMinutes(walkToBoardMeters);
    final busRideMinutes = totalMinutes - walkToBoardMinutes - walkFromStopMinutes;

    final totalDistanceMeters = walkToBoardMeters +
        walkFromStopMeters +
        calculateSegmentDistance(allRouteStops);

    return TouristBusRoutePlan(
      place: place,
      destinationStop: destinationStop,
      line: segments.first.line,
      boardingStop: segments.first.boardingStop,
      segments: segments,
      routeStops: allRouteStops,
      routePoints: routePoints,
      walkToBoardMeters: walkToBoardMeters,
      walkToBoardMinutes: walkToBoardMinutes,
      walkFromStopToPlaceMeters: walkFromStopMeters,
      walkFromStopToPlaceMinutes: walkFromStopMinutes,
      busRideMinutes: busRideMinutes.clamp(0, 999),
      totalDistanceMeters: totalDistanceMeters,
      totalDurationMinutes: totalMinutes,
    );
  }

  // ── Reconstruct segments from DP back-pointers ────────────────────────────

  static List<TouristBusSegment> _reconstructSegments(
    _Node destinationNode,
    Map<String, StopModel> stopById,
  ) {
    // Walk back through prev pointers collecting (line, stopId) pairs
    var path = <_Node>[];
    _Node? n = destinationNode;
    while (n != null) {
      path.add(n);
      n = n.prev;
    }
    path = path.reversed.toList();

    // Group consecutive nodes that share the same line into segments
    final segments = <TouristBusSegment>[];
    var segStart = 0;

    for (var i = 1; i <= path.length - 1; i++) {
      final isLast = i == path.length - 1;

      if (isLast || (path[i].lineUsed != null &&
          i + 1 < path.length &&
          path[i + 1].lineUsed != null &&
          path[i].lineUsed!.id != path[i + 1].lineUsed!.id)) {
        // Segment from segStart to i
        final segNodes = path.sublist(segStart, i + 1);
        final line = segNodes.last.lineUsed;
        if (line == null) { segStart = i; continue; }

        final stops = segNodes
            .map((node) => stopById[node.stopId])
            .whereType<StopModel>()
            .toList();

        if (stops.length < 2) { segStart = i; continue; }

        segments.add(TouristBusSegment(
          line: line,
          boardingStop: stops.first,
          destinationStop: stops.last,
          routeStops: stops,
        ));
        segStart = i;
      }
    }

    return segments;
  }

  // ── Nearby stops (unchanged API, uses buildPlan internally) ───────────────

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
            maxWalkToBoardMeters: maxWalkToBoardMeters.isInfinite
                ? 1200
                : maxWalkToBoardMeters,
            minSavingMinutes: 0, // show all options in the sheet
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
      if (a.walkFromUserToBoardMeters != null && b.walkFromUserToBoardMeters != null) {
        final d = a.walkFromUserToBoardMeters!.compareTo(b.walkFromUserToBoardMeters!);
        if (d != 0) return d;
      }
      return a.distanceToPlaceMeters.compareTo(b.distanceToPlaceMeters);
    });

    return options.length <= limit ? options : options.take(limit).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static double _distanceAlongStops(List<StopModel> stops) {
    var d = 0.0;
    for (var i = 0; i < stops.length - 1; i++) {
      d += Geolocator.distanceBetween(
        stops[i].lat, stops[i].lon,
        stops[i + 1].lat, stops[i + 1].lon,
      );
    }
    return d;
  }
}
