import '../models/tourist_place.dart';
import '../utils/tourist_bus_route_planner.dart';

/// Formats a [TouristBusRoutePlan] into a list of readable step-by-step instructions.
List<String> buildBusRouteInstructions(TouristBusRoutePlan plan, TouristPlace place) {
  final instructions = <String>[
    'Camina ${plan.walkToBoardMeters.round()} m (${plan.walkToBoardMinutes} min aprox.) hasta ${plan.segments.first.boardingStop.name}.',
  ];

  for (var i = 0; i < plan.segments.length; i++) {
    final segment = plan.segments[i];
    final busStopsCount = segment.routeStops.length - 1;

    if (i == 0) {
      instructions.add(
        'Subete a la línea ${segment.line.name} en ${segment.boardingStop.name}.',
      );
    } else {
      instructions.add(
        'En ${segment.boardingStop.name}, haz transbordo a la línea ${segment.line.name}.',
      );
    }

    instructions.add(
      'Sigue $busStopsCount paradas y bajate en ${segment.destinationStop.name}.',
    );
  }

  instructions.add(
    'Camina ${plan.walkFromStopToPlaceMeters.round()} m (${plan.walkFromStopToPlaceMinutes} min aprox.) para llegar a ${place.name}.',
  );

  return instructions;
}
