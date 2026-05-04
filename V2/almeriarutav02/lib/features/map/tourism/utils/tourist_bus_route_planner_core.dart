import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/services/line_models.dart';
import '../models/tourist_place.dart';
import 'tourist_bus_route_planner_helpers.dart';
import 'tourist_bus_route_planner_models.dart';

class TouristBusRoutePlanner {

  // ─────────────────────────────────────────────
  // 🟢 PARADAS CERCANAS AL DESTINO
  // ─────────────────────────────────────────────
  static List<TouristNearbyStopOption> findNearbyStops({
    required TouristPlace place,
    required List<StopModel> allStops,
    required List<LineModel> allLines,
    LatLng? userLocation,
    double maxDistanceMeters = 1600,
    double? maxWalkToBoardMeters,
    int limit = 20,
  }) {
    final options = <TouristNearbyStopOption>[];

    for (final stop in allStops) {
      final distanceToPlace = Geolocator.distanceBetween(
        place.location.latitude,
        place.location.longitude,
        stop.lat,
        stop.lon,
      );

      if (distanceToPlace > maxDistanceMeters) continue;

      final servingLines = allLines
          .where((line) => stop.lineIds.contains(line.id))
          .toList();

      double? walkFromUser;
      if (userLocation != null) {
        walkFromUser = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          stop.lat,
          stop.lon,
        );

        if (maxWalkToBoardMeters != null && walkFromUser > maxWalkToBoardMeters) continue;
      }

      options.add(TouristNearbyStopOption(
        stop: stop,
        distanceToPlaceMeters: distanceToPlace,
        servingLines: servingLines,
        walkFromUserToBoardMeters: walkFromUser,
      ));
    }

    options.sort((a, b) => a.distanceToPlaceMeters.compareTo(b.distanceToPlaceMeters));

    return options.take(limit).toList();
  }

  // ─────────────────────────────────────────────
  // 🔵 GENERA MEJORES PLANES
  // ─────────────────────────────────────────────
  static List<TouristBusRoutePlan> buildBestPlans({
    required TouristPlace place,
    required LatLng userLocation,
    required List<LineModel> allLines,
    required List<StopModel> allStops,
  }) {
    final nearbyStops = findNearbyStops(
      place: place,
      allStops: allStops,
      allLines: allLines,
      userLocation: userLocation,
    );

    final plans = <TouristBusRoutePlan>[];

    for (final option in nearbyStops) {
      final plan = buildPlan(
        place: place,
        userLocation: userLocation,
        destinationStop: option.stop,
        allLines: allLines,
      );

      if (plan != null && plan.segments.length <= 2) {
        plans.add(plan);
      }
    }

    plans.sort((a, b) =>
        a.totalDurationMinutes.compareTo(b.totalDurationMinutes));

    return plans.take(3).toList();
  }

  // ─────────────────────────────────────────────
  // 🟡 ALGORITMO PRINCIPAL
  // ─────────────────────────────────────────────
  static TouristBusRoutePlan? buildPlan({
    required TouristPlace place,
    required LatLng userLocation,
    required StopModel destinationStop,
    required List<LineModel> allLines,
    double maxWalkToBoardMeters = 800,
  }) {

    
    double distToUser(StopModel s) => Geolocator.distanceBetween(
        userLocation.latitude, userLocation.longitude, s.lat, s.lon);

    double distToPlace(StopModel s) => Geolocator.distanceBetween(
        s.lat, s.lon, place.location.latitude, place.location.longitude);

    final Map<String, StopModel> uniqueStops = {};
    for (final line in allLines) {
      for (final stop in line.stops) {
        uniqueStops[stop.id] = stop;
      }
    }

    final userNearbyStops = uniqueStops.values
        .where((s) => distToUser(s) <= maxWalkToBoardMeters)
        .toList()
      ..sort((a, b) => distToUser(a).compareTo(distToUser(b)));

    if (userNearbyStops.isEmpty) return null;

    TouristBusRoutePlan? best;
    final destLineIds = destinationStop.lineIds.toSet();

    // ───────────── DIRECTO ─────────────

    for (final boarding in userNearbyStops) {
      final commonLineIds = boarding.lineIds.toSet().intersection(destLineIds);

      if (commonLineIds.isEmpty) continue;

      for (final lineId in commonLineIds) {
        final line = allLines.firstWhere((l) => l.id == lineId);
        final routeStops = _extractCleanRoute(line.stops, boarding.id, destinationStop.id);
        
        if (routeStops == null || routeStops.length > 40) continue;

        final plan = _makePlan(
          place: place,
          userLocation: userLocation,
          segments: [
            TouristBusSegment(
              line: line,
              boardingStop: boarding,
              destinationStop: destinationStop,
              routeStops: routeStops,
            )
          ],
          distToUser: distToUser,
          distToPlace: distToPlace,
        );

        if (isBetterPlan(plan, best)) {
          best = plan;
     
        }
      }
    }

    if (best != null) {

      return best;
    }

    // ───────────── TRANSBORDO ─────────────

    for (final boarding in userNearbyStops.take(15)) {
      
      for (final line1Id in boarding.lineIds) {
        final line1 = allLines.firstWhere((l) => l.id == line1Id);

        final uniqueTransferStops = <String, StopModel>{};
        for (final s in line1.stops) {
          if (s.id != boarding.id) {
            uniqueTransferStops[s.id] = s;
          }
        }

        for (final transfer in uniqueTransferStops.values) {
          
          final transferToDestLines = transfer.lineIds.toSet().intersection(destLineIds);
          transferToDestLines.remove(line1.id);
          
          if (transferToDestLines.isEmpty) continue;

          for (final line2Id in transferToDestLines) {
            final line2 = allLines.firstWhere((l) => l.id == line2Id);

            final seg1 = _extractCleanRoute(line1.stops, boarding.id, transfer.id);
            if (seg1 == null) continue;

            final seg2 = _extractCleanRoute(line2.stops, transfer.id, destinationStop.id);
            if (seg2 == null) continue;

            if (seg1.length + seg2.length > 45) continue;

            final plan = _makePlan(
              place: place,
              userLocation: userLocation,
              segments: [
                TouristBusSegment(
                  line: line1,
                  boardingStop: boarding,
                  destinationStop: transfer,
                  routeStops: seg1,
                ),
                TouristBusSegment(
                  line: line2,
                  boardingStop: transfer,
                  destinationStop: destinationStop,
                  routeStops: seg2,
                ),
              ],
              distToUser: distToUser,
              distToPlace: distToPlace,
            );

            if (isBetterPlan(plan, best)) {
              best = plan;

            }
          }
        }
      }
    }
    return best;
  }

  // ─────────────────────────────────────────────
  // 🛡️ EXTRACTOR LIMPIO (ARRAY CIRCULAR - ORDEN PERFECTO)
  // ─────────────────────────────────────────────
  static List<StopModel>? _extractCleanRoute(List<StopModel> stops, String boardId, String destId) {
    if (stops.isEmpty) return null;

    // 🔥 EL TRUCO MAGICO: Duplicar la ruta para simular el ciclo circular 🔥
    // Esto asegura que SIEMPRE avanzamos hacia adelante y las paradas 
    // mantienen su orden geográfico exacto en las calles.
    final extendedStops = [...stops, ...stops];
    final originalLength = stops.length;

    List<StopModel>? bestCandidate;
    int minLength = 99999;

    for (int i = 0; i < originalLength; i++) {
      if (extendedStops[i].id == boardId) {
        // Buscamos hacia adelante un máximo de 1 vuelta completa
        for (int j = i + 1; j < i + originalLength; j++) {
          if (extendedStops[j].id == destId) {
            final candidate = extendedStops.sublist(i, j + 1);
            if (candidate.length < minLength) {
              minLength = candidate.length;
              bestCandidate = candidate;
            }
          }
        }
      }
    }

    if (bestCandidate == null) return null;

    // Filtro de suavizado (ahora que el orden es real, casi nunca se saltarán paradas)
    final cleaned = <StopModel>[bestCandidate.first];
    
    for (int i = 1; i < bestCandidate.length - 1; i++) {
      final current = bestCandidate[i];
      final previous = cleaned.last;
      
      final dist = Geolocator.distanceBetween(
        previous.lat, previous.lon,
        current.lat, current.lon,
      );

      // 3km de margen. Solo descarta si el GTFS tiene una coordenada muy corrupta.
      if (dist <= 3000) {
        cleaned.add(current);
      }
    }

    if (bestCandidate.length > 1) {
      cleaned.add(bestCandidate.last);
    }

    return cleaned;
  }

  // ─────────────────────────────────────────────
  // 🟣 CREAR PLAN FINAL
  // ─────────────────────────────────────────────
  static TouristBusRoutePlan _makePlan({
    required TouristPlace place,
    required LatLng userLocation,
    required List<TouristBusSegment> segments,
    required double Function(StopModel) distToUser,
    required double Function(StopModel) distToPlace,
  }) {
    final allStops = segments.expand((s) => s.routeStops).toList();

    final walkToBoard = distToUser(segments.first.boardingStop);
    final walkToPlace = distToPlace(segments.last.destinationStop);

    final busDistance = calculateSegmentDistance(allStops);

    return TouristBusRoutePlan(
      place: place,
      destinationStop: segments.last.destinationStop,
      line: segments.first.line,
      boardingStop: segments.first.boardingStop,
      segments: segments,
      routeStops: allStops,
      routePoints: [
        userLocation,
        ...allStops.map((s) => LatLng(s.lat, s.lon)),
        place.location,
      ],
      walkToBoardMeters: walkToBoard,
      walkToBoardMinutes: estimateWalkingMinutes(walkToBoard),
      walkFromStopToPlaceMeters: walkToPlace,
      walkFromStopToPlaceMinutes: estimateWalkingMinutes(walkToPlace),
      busRideMinutes: estimateBusRideMinutes(allStops.length),
      totalDistanceMeters: walkToBoard + walkToPlace + busDistance,
      totalDurationMinutes:
          estimateWalkingMinutes(walkToBoard) +
          estimateWalkingMinutes(walkToPlace) +
          estimateBusRideMinutes(allStops.length),
    );
  }
}