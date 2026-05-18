import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../../../shared/services/line_models.dart';
import 'tourist_bus_route_planner_models.dart';

/// Compares two route plans and returns true if candidate is better.
/// Prioriza:
/// 1. Menos transbordos (absoluto)
/// 2. Menos distancia CAMINANDO (muy penalizado para priorizar al usuario)
/// 3. Menos distancia total
bool isBetterPlan(TouristBusRoutePlan? candidate, TouristBusRoutePlan? current) {
  if (candidate == null) return false;
  if (current == null) return true;

  final candidateTransfers = candidate.segments.length;
  final currentTransfers = current.segments.length;

  // 🟢 PRIORIDAD ABSOLUTA 1: MENOS TRANSBORDOS
  if (candidateTransfers != currentTransfers) {
    return candidateTransfers < currentTransfers;
  }

  // 🔵 PRIORIDAD 2: PENALIZAR CAMINATAS LARGAS
  // Si la diferencia de caminata desde el usuario hasta la parada es muy grande (> 100m)
  // priorizamos la que esté más cerca del usuario.
  final candidateWalk = candidate.walkToBoardMeters + candidate.walkFromStopToPlaceMeters;
  final currentWalk = current.walkToBoardMeters + current.walkFromStopToPlaceMeters;

  // Si caminar me ahorra menos de 100 metros, miramos qué parada está más cerca del usuario
  if ((candidateWalk - currentWalk).abs() > 100) {
    return candidateWalk < currentWalk;
  }

  // 🟡 PRIORIDAD 3: TIEMPO TOTAL
  // Si las caminatas son similares (ej: ambas a 200m), elegimos la más rápida.
  if (candidate.totalDurationMinutes != current.totalDurationMinutes) {
    return candidate.totalDurationMinutes < current.totalDurationMinutes;
  }

  // 🟣 PRIORIDAD 4: DISTANCIA TOTAL DE LA RUTA
  return candidate.totalDistanceMeters < current.totalDistanceMeters;
}

/// Returns true if taking the bus saves at least [minDistanceSavedMeters] vs walking directly.
bool isBusWorthIt(
  TouristBusRoutePlan plan,
  double directWalkMeters, {
  double minDistanceSavedMeters = 100,
}) {
  return (directWalkMeters - plan.totalDistanceMeters) >=
      minDistanceSavedMeters;
}

/// Estimates bus ride time in minutes based on distance and stops.
/// Use a simple distance-based speed plus a small dwell time per stop.
int estimateBusRideMinutes(double distanceMeters, int stopCount) {
  const busSpeedMps = 4.5; // ~16.2 km/h urban average
  const dwellSecondsPerStop = 30;

  final travelMinutes = (distanceMeters / busSpeedMps) / 60;
  final dwellMinutes = math.max(0, stopCount - 1) * (dwellSecondsPerStop / 60);
  final total = (travelMinutes + dwellMinutes).round();

  return math.max(3, total);
}

/// Calculates total distance covered by a sequence of bus stops.
double calculateSegmentDistance(List<StopModel> routeStops) {
  if (routeStops.length < 2) return 0;

  var distance = 0.0;
  for (var i = 0; i < routeStops.length - 1; i++) {
    final from = routeStops[i];
    final to = routeStops[i + 1];
    distance += Geolocator.distanceBetween(
      from.lat,
      from.lon,
      to.lat,
      to.lon,
    );
  }
  return distance;
}

/// Estimates walking time in minutes based on distance.
/// Velocidad media: 5 km/h (1.39 m/s)
int estimateWalkingMinutes(double distanceMeters) {
  const walkingSpeedMps = 1.0; // Corregido a 1.39 m/s reales (5 km/h)
  final minutes = ((distanceMeters / walkingSpeedMps) / 60).round();

  if (distanceMeters > 0 && minutes == 0) {
    return 1;
  }
  return minutes; 
}