import '../../../../shared/services/line_models.dart';
import '../models/tourist_place.dart';
import 'package:latlong2/latlong.dart';

/// Represents a nearby bus stop option for reaching a tourist place.
class TouristNearbyStopOption {
  final StopModel stop;
  final double distanceToPlaceMeters;
  final List<LineModel> servingLines;
  final double? walkFromUserToBoardMeters;

  const TouristNearbyStopOption({
    required this.stop,
    required this.distanceToPlaceMeters,
    required this.servingLines,
    this.walkFromUserToBoardMeters,
  });
}

/// Represents a complete bus route plan from user location to a tourist place.
class TouristBusRoutePlan {
  final TouristPlace place;
  final StopModel destinationStop;
  final LineModel line;
  final StopModel boardingStop;
  final List<TouristBusSegment> segments;
  final List<StopModel> routeStops;
  final List<LatLng> routePoints;
  final double walkToBoardMeters;
  final int walkToBoardMinutes;
  final double walkFromStopToPlaceMeters;
  final int walkFromStopToPlaceMinutes;
  final int busRideMinutes;
  final double totalDistanceMeters;
  final int totalDurationMinutes;

  const TouristBusRoutePlan({
    required this.place,
    required this.destinationStop,
    required this.line,
    required this.boardingStop,
    required this.segments,
    required this.routeStops,
    required this.routePoints,
    required this.walkToBoardMeters,
    required this.walkToBoardMinutes,
    required this.walkFromStopToPlaceMeters,
    required this.walkFromStopToPlaceMinutes,
    required this.busRideMinutes,
    required this.totalDistanceMeters,
    required this.totalDurationMinutes,
  });

  String get routeStopsLabel => routeStops.map((stop) => stop.name).join(' · ');

  bool get hasTransfer => segments.length > 1;

  String get linesLabel => segments.map((segment) => segment.line.name).join(' -> ');

  String get summaryLabel =>
      '$linesLabel: ${boardingStop.name} -> ${destinationStop.name}';
}

/// Represents a single bus leg in a multi-segment route.
class TouristBusSegment {
  final LineModel line;
  final StopModel boardingStop;
  final StopModel destinationStop;
  final List<StopModel> routeStops;

  const TouristBusSegment({
    required this.line,
    required this.boardingStop,
    required this.destinationStop,
    required this.routeStops,
  });
}

/// Internal helper class for direct segment planning.
class DirectSegmentPlan {
  final TouristBusSegment segment;
  final double walkToBoardMeters;

  const DirectSegmentPlan({
    required this.segment,
    required this.walkToBoardMeters,
  });
}
