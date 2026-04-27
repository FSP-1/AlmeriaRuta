import 'package:latlong2/latlong.dart';
import '../tourism/utils/tourist_bus_route_planner.dart';
import 'osrm_routing_service.dart';

class TouristBusRoutePolylineParts {
  final List<LatLng> walkToBoard;
  final List<LatLng> busRoute;
  final List<LatLng> walkToPlace;

  const TouristBusRoutePolylineParts({
    required this.walkToBoard,
    required this.busRoute,
    required this.walkToPlace,
  });

  List<LatLng> get combined {
    final points = <LatLng>[];
    void append(List<LatLng> segment) {
      if (segment.isEmpty) return;
      if (points.isEmpty) {
        points.addAll(segment);
        return;
      }
      final last = points.last;
      final next = segment.first;
      if (last == next) {
        points.addAll(segment.skip(1));
      } else {
        points.addAll(segment);
      }
    }

    append(walkToBoard);
    append(busRoute);
    append(walkToPlace);
    return points;
  }
}

/// Builds polyline parts for a TouristBusRoutePlan:
/// walk to boarding (walking via OSRM) + bus legs (exact line stop sequence)
/// + walk to place (walking via OSRM).
class BusRoutePolylineBuilder {
  final OsrmRoutingService _routing;

  BusRoutePolylineBuilder({OsrmRoutingService? routing})
      : _routing = routing ?? OsrmRoutingService();

  Future<TouristBusRoutePolylineParts> buildParts(
    TouristBusRoutePlan plan,
    LatLng userLocation,
  ) async {
    final walkToBoard = <LatLng>[];
    final busRoute = <LatLng>[];
    final walkToPlace = <LatLng>[];

    // 1. Walk: user → first boarding stop
    final boarding = plan.segments.first.boardingStop;
    walkToBoard.addAll(await _routing.getSegmentPoints(
      userLocation,
      LatLng(boarding.lat, boarding.lon),
      profile: 'walking',
    ));

    // 2. Bus legs: follow the planned line stop sequence exactly.
    // This avoids OSRM road shortcuts that can diverge from the selected line.
    for (final segment in plan.segments) {
      final stops = segment.routeStops;
      for (final stop in stops) {
        final busPoint = LatLng(stop.lat, stop.lon);
        if (busRoute.isEmpty || busRoute.last != busPoint) {
          busRoute.add(busPoint);
        }
      }
    }

    // 3. Walk: last stop → tourist place
    final lastStop = plan.segments.last.destinationStop;
    walkToPlace.addAll(await _routing.getSegmentPoints(
      LatLng(lastStop.lat, lastStop.lon),
      plan.place.location,
      profile: 'walking',
    ));

    return TouristBusRoutePolylineParts(
      walkToBoard: walkToBoard,
      busRoute: busRoute,
      walkToPlace: walkToPlace,
    );
  }

  Future<List<LatLng>> build(TouristBusRoutePlan plan, LatLng userLocation) async {
    final parts = await buildParts(plan, userLocation);
    return parts.combined.isEmpty ? plan.routePoints : parts.combined;
  }
}
