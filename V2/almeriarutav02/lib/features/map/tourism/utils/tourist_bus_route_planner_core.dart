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

        if (maxWalkToBoardMeters != null &&
            walkFromUser > maxWalkToBoardMeters) continue;
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
  // 🟡 ALGORITMO PRINCIPAL (SÚPER OPTIMIZADO)
  // ─────────────────────────────────────────────
  static TouristBusRoutePlan? buildPlan({
    required TouristPlace place,
    required LatLng userLocation,
    required StopModel destinationStop,
    required List<LineModel> allLines,
    double maxWalkToBoardMeters = 800,
  }) {
    print('\n========================================================');
    print('📍 INICIANDO RUTEO HACIA DESTINO: ${destinationStop.name}');
    print('Líneas del destino: ${destinationStop.lineIds}');
    
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

    // ───────────── DIRECTO (INTERSECCIÓN EXACTA) ─────────────
    print('--- BUSCANDO RUTA DIRECTA ---');
    for (final boarding in userNearbyStops) {
      final commonLineIds = boarding.lineIds.toSet().intersection(destLineIds);

      if (commonLineIds.isEmpty) continue;

      for (final lineId in commonLineIds) {
        final line = allLines.firstWhere((l) => l.id == lineId);
        final routeStops = _extractCleanRoute(line.stops, boarding.id, destinationStop.id);
        
        if (routeStops == null || routeStops.length > 30) continue;

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
          print('✅ [NUEVO MEJOR DIRECTO] ${line.name} desde ${boarding.name}');
        }
      }
    }

    if (best != null) {
      print('🏆 SELECCIONADO PLAN DIRECTO FINAL: ${best.line.name}');
      print('========================================================\n');
      return best;
    }

    // ───────────── TRANSBORDO (OPTIMIZADO CON SETS) ─────────────
    print('--- NO HAY DIRECTO, BUSCANDO TRANSBORDOS ---');
    for (final boarding in userNearbyStops.take(15)) {
      
      for (final line1Id in boarding.lineIds) {
        final line1 = allLines.firstWhere((l) => l.id == line1Id);

        // 1. Extraemos paradas únicas de la línea 1 para evitar evaluar la misma parada varias veces
        final uniqueTransferStops = <String, StopModel>{};
        for (final s in line1.stops) {
          if (s.id != boarding.id) {
            uniqueTransferStops[s.id] = s;
          }
        }

        // 2. Iteramos por las paradas candidatas a transbordo
        for (final transfer in uniqueTransferStops.values) {
          
          // ¿Esta parada comparte alguna línea con el destino?
          final transferToDestLines = transfer.lineIds.toSet().intersection(destLineIds);
          transferToDestLines.remove(line1.id); // Evitamos "transbordar" a la misma línea
          
          if (transferToDestLines.isEmpty) continue;

          for (final line2Id in transferToDestLines) {
            final line2 = allLines.firstWhere((l) => l.id == line2Id);

            final seg1 = _extractCleanRoute(line1.stops, boarding.id, transfer.id);
            if (seg1 == null) continue;

            final seg2 = _extractCleanRoute(line2.stops, transfer.id, destinationStop.id);
            if (seg2 == null) continue;

            if (seg1.length + seg2.length > 35) continue;

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

            // SOLO imprime si es mejor que lo que ya teníamos
            if (isBetterPlan(plan, best)) {
              best = plan;
              print('🔄 [NUEVO MEJOR TRANSBORDO]');
              print('   Sube en: ${boarding.name} (Línea ${line1.name})');
              print('   Cambia en: ${transfer.name} (A la línea ${line2.name})');
              print('   Total paradas viaje: ${seg1.length + seg2.length}');
            }
          }
        }
      }
    }
    print('========================================================\n');
    return best;
  }

  // ─────────────────────────────────────────────
  // 🛡️ EXTRACTOR LIMPIO (SOPORTA IDA Y VUELTA)
  // ─────────────────────────────────────────────
  static List<StopModel>? _extractCleanRoute(List<StopModel> stops, String boardId, String destId) {
    List<StopModel>? bestRawSegment;
    int minLength = 99999;

    for (int i = 0; i < stops.length; i++) {
      if (stops[i].id == boardId) {
        for (int j = 0; j < stops.length; j++) {
          if (stops[j].id == destId && i != j) {
            
            List<StopModel> candidate;
            if (i < j) {
              candidate = stops.sublist(i, j + 1);
            } else {
              candidate = stops.sublist(j, i + 1).reversed.toList();
            }

            if (candidate.length < minLength) {
              minLength = candidate.length;
              bestRawSegment = candidate;
            }
          }
        }
      }
    }

    if (bestRawSegment == null) return null;

    final cleaned = <StopModel>[bestRawSegment.first];
    
    for (int i = 1; i < bestRawSegment.length - 1; i++) {
      final current = bestRawSegment[i];
      final previous = cleaned.last;
      
      final distToPrev = Geolocator.distanceBetween(
        previous.lat, previous.lon,
        current.lat, current.lon,
      );

      if (distToPrev <= 1500) {
        cleaned.add(current);
      }
    }

    if (bestRawSegment.length > 1) {
      cleaned.add(bestRawSegment.last);
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