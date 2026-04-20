import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../../../shared/services/line_models.dart';
import 'tourist_bus_route_planner_models.dart';

/// Compares two route plans and returns true if candidate is better.
/// Direct routes (no transfer) are strongly preferred over transfer routes
/// unless the transfer saves more than 8 minutes.
bool isBetterPlan(TouristBusRoutePlan? candidate, TouristBusRoutePlan? current) {
  if (candidate == null) return false;
  if (current == null) return true;

  // Penalise each transfer with 8 minutes (waiting + walking between stops).
  const transferPenaltyMinutes = 8;
  final candidateAdjusted =
      candidate.totalDurationMinutes + (candidate.segments.length - 1) * transferPenaltyMinutes;
  final currentAdjusted =
      current.totalDurationMinutes + (current.segments.length - 1) * transferPenaltyMinutes;

  if (candidateAdjusted != currentAdjusted) {
    return candidateAdjusted < currentAdjusted;
  }
  // Tie-break: fewer transfers, then less walking to board.
  if (candidate.segments.length != current.segments.length) {
    return candidate.segments.length < current.segments.length;
  }
  return candidate.walkToBoardMeters < current.walkToBoardMeters;
}

/// Returns true if taking the bus saves at least [minSavingMinutes] vs walking directly.
bool isBusWorthIt(TouristBusRoutePlan plan, double directWalkMeters, {int minSavingMinutes = 5}) {
  final directWalkMinutes = estimateWalkingMinutes(directWalkMeters);
  return (directWalkMinutes - plan.totalDurationMinutes) >= minSavingMinutes;
}

/// Estimates bus ride time in minutes based on number of stops.
/// Uses 2 min/stop which is more realistic for Almería urban lines.
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
/// Assumes average walking speed of 1.39 m/s (5 km/h).
int estimateWalkingMinutes(double distanceMeters) {
  const walkingSpeedMps = 1.39;
  final minutes = ((distanceMeters / walkingSpeedMps) / 60).round();
  if (distanceMeters > 0 && minutes == 0) {
    return 1;
  }
  return minutes;
}
