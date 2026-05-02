import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../../../shared/services/line_models.dart';
import 'tourist_bus_route_planner_models.dart';

/// Compares two route plans and returns true if candidate is better.
/// Prioriza:
/// - Menos caminata
/// - Menos transbordos (muy importante)
/// - Rutas más directas
bool isBetterPlan(TouristBusRoutePlan? candidate, TouristBusRoutePlan? current) {
  if (candidate == null) return false;
  if (current == null) return true;

  final candidateTransfers = candidate.segments.length;
  final currentTransfers = current.segments.length;

  // 🟢 PRIORIDAD ABSOLUTA: MENOS TRANSBORDOS
  if (candidateTransfers != currentTransfers) {
    return candidateTransfers < currentTransfers;
  }

  // 🔵 luego distancia real
  final candidateDistance = candidate.totalDistanceMeters;
  final currentDistance = current.totalDistanceMeters;

  if (candidateDistance != currentDistance) {
    return candidateDistance < currentDistance;
  }

  // 🟡 luego caminata
  final candidateWalk = candidate.walkToBoardMeters +
      candidate.walkFromStopToPlaceMeters;

  final currentWalk = current.walkToBoardMeters +
      current.walkFromStopToPlaceMeters;

  return candidateWalk < currentWalk;
}

/// Returns true if taking the bus saves at least [minDistanceSavedMeters] vs walking directly.
bool isBusWorthIt(
  TouristBusRoutePlan plan,
  double directWalkMeters, {
  double minDistanceSavedMeters = 100, // 🔥 subido para evitar sugerencias absurdas
}) {
  return (directWalkMeters - plan.totalDistanceMeters) >=
      minDistanceSavedMeters;
}

/// Estimates bus ride time in minutes based on number of stops.
/// Aproximación realista: ~2 min por parada
int estimateBusRideMinutes(int stopCount) {
  return math.max(2, (stopCount - 1) * 2);
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
  const walkingSpeedMps = 1.0;
  final minutes = ((distanceMeters / walkingSpeedMps) / 60).round();

  if (distanceMeters > 0 && minutes == 0) {
    return 1;
  }
  return minutes;
}