import 'package:latlong2/latlong.dart';
import '../tourism/utils/tourist_bus_route_planner.dart';
import 'osrm_routing_service.dart';

/// Builds a full OSRM polyline for a TouristBusRoutePlan:
/// walk to boarding (walking) + bus legs (driving) + walk to place (walking).
class BusRoutePolylineBuilder {
  final OsrmRoutingService _routing;

  BusRoutePolylineBuilder({OsrmRoutingService? routing})
      : _routing = routing ?? OsrmRoutingService();

  Future<List<LatLng>> build(TouristBusRoutePlan plan, LatLng userLocation) async {
    final points = <LatLng>[];

    // 1. Walk: user → first boarding stop
    final boarding = plan.segments.first.boardingStop;
    points.addAll(await _routing.getSegmentPoints(
      userLocation,
      LatLng(boarding.lat, boarding.lon),
      profile: 'walking',
    ));

    // 2. Bus legs: each consecutive stop pair in every segment
    for (final segment in plan.segments) {
      final stops = segment.routeStops;
      for (var i = 0; i < stops.length - 1; i++) {
        final leg = await _routing.getSegmentPoints(
          LatLng(stops[i].lat, stops[i].lon),
          LatLng(stops[i + 1].lat, stops[i + 1].lon),
          profile: 'driving',
        );
        if (points.isNotEmpty && leg.isNotEmpty) {
          points.addAll(leg.skip(1));
        } else {
          points.addAll(leg);
        }
      }
    }

    // 3. Walk: last stop → tourist place
    final lastStop = plan.segments.last.destinationStop;
    final walkToPlace = await _routing.getSegmentPoints(
      LatLng(lastStop.lat, lastStop.lon),
      plan.place.location,
      profile: 'walking',
    );
    if (walkToPlace.isNotEmpty) points.addAll(walkToPlace.skip(1));

    return points.isEmpty ? plan.routePoints : points;
  }
}
