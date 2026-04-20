import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:almeriarutav02/features/map/tourism/models/tourist_place.dart';
import 'package:almeriarutav02/features/map/tourism/utils/tourist_bus_route_planner.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';

void main() {
  group('TouristBusRoutePlanner', () {
    final place = TouristPlace(
      id: 'alcazaba',
      name: 'Alcazaba',
      location: const LatLng(36.841, -2.467),
      description: 'Monumento',
      category: TouristCategory.monument,
    );

    final userLocation = const LatLng(36.838, -2.460);

    final line = LineModel(
      id: 'L1',
      name: 'L1',
      fullName: 'Linea 1',
      description: 'Centro',
      frequency: '15 min',
      firstService: '06:30',
      lastService: '22:30',
      totalStops: 4,
      stops: [
        StopModel(id: 's1', name: 'Origen', lat: 36.8380, lon: -2.4600, zone: 'A', lineIds: {'L1'}),
        StopModel(id: 's2', name: 'Intermedia', lat: 36.8390, lon: -2.4630, zone: 'A', lineIds: {'L1'}),
        StopModel(id: 's3', name: 'Destino', lat: 36.8405, lon: -2.4660, zone: 'A', lineIds: {'L1'}),
      ],
    );

    test('findNearbyStops returns stops ordered by distance to tourist place', () {
      final stops = [
        StopModel(id: 'a', name: 'Lejana', lat: 36.8300, lon: -2.4500, zone: 'A', lineIds: {'L1'}),
        StopModel(id: 'b', name: 'Cercana', lat: 36.8408, lon: -2.4668, zone: 'A', lineIds: {'L1'}),
        StopModel(id: 'c', name: 'Muy cercana', lat: 36.8412, lon: -2.4672, zone: 'A', lineIds: {'L1'}),
      ];

      final options = TouristBusRoutePlanner.findNearbyStops(
        place: place,
        allStops: stops,
        allLines: [line],
        maxDistanceMeters: 2000,
      );

      expect(options, hasLength(3));
      expect(options.first.stop.id, 'c');
      expect(options.last.stop.id, 'a');
    });

    test('buildPlan chooses a direct line segment from the nearest boarding stop', () {
      final plan = TouristBusRoutePlanner.buildPlan(
        place: place,
        userLocation: userLocation,
        destinationStop: line.stops[2],
        allLines: [line],
      );

      expect(plan, isNotNull);
      expect(plan!.line.id, 'L1');
      expect(plan.boardingStop.id, 's1');
      expect(plan.destinationStop.id, 's3');
      expect(plan.routeStops.map((s) => s.id), ['s1', 's2', 's3']);
      expect(plan.routePoints.length, greaterThanOrEqualTo(4));
      expect(plan.totalDurationMinutes, greaterThan(0));
    });

    test('buildPlan can choose a one-transfer route when it is better than direct walking to final line', () {
      final user = const LatLng(36.8380, -2.4600);
      final transfer = StopModel(
        id: 't1',
        name: 'Intercambiador',
        lat: 36.8500,
        lon: -2.5000,
        zone: 'A',
        lineIds: const {'L1', 'L2'},
      );

      final line1 = LineModel(
        id: 'L1',
        name: 'L1',
        fullName: 'Linea 1',
        description: 'Barrio a intercambiador',
        frequency: '10 min',
        firstService: '06:30',
        lastService: '22:30',
        totalStops: 3,
        stops: [
          StopModel(id: 'u1', name: 'Cerca usuario', lat: 36.8381, lon: -2.4601, zone: 'A', lineIds: const {'L1'}),
          StopModel(id: 'u2', name: 'Intermedia L1', lat: 36.8440, lon: -2.4800, zone: 'A', lineIds: const {'L1'}),
          transfer,
        ],
      );

      final destination = StopModel(
        id: 'd1',
        name: 'Destino turístico',
        lat: 36.8410,
        lon: -2.4670,
        zone: 'A',
        lineIds: const {'L2'},
      );

      final line2 = LineModel(
        id: 'L2',
        name: 'L2',
        fullName: 'Linea 2',
        description: 'Intercambiador a turismo',
        frequency: '12 min',
        firstService: '06:30',
        lastService: '22:30',
        totalStops: 3,
        stops: [
          StopModel(id: 'f0', name: 'Lejana L2', lat: 36.8600, lon: -2.5100, zone: 'A', lineIds: const {'L2'}),
          transfer,
          destination,
        ],
      );

      final plan = TouristBusRoutePlanner.buildPlan(
        place: place,
        userLocation: user,
        destinationStop: destination,
        allLines: [line1, line2],
      );

      expect(plan, isNotNull);
      expect(plan!.segments.length, 2);
      expect(plan.hasTransfer, isTrue);
      expect(plan.segments.first.line.id, 'L1');
      expect(plan.segments.last.line.id, 'L2');
      expect(plan.segments.last.destinationStop.id, 'd1');
    });

    test('findNearbyStops does not block options for users far from tourist destination stops', () {
      final farUser = const LatLng(36.9000, -2.5200);

      final options = TouristBusRoutePlanner.findNearbyStops(
        place: place,
        allStops: line.stops,
        allLines: [line],
        userLocation: farUser,
        maxDistanceMeters: 2000,
      );

      expect(options, isNotEmpty);
      expect(options.first.walkFromUserToBoardMeters, isNotNull);
    });

    test('findNearbyStops can still enforce explicit max walk threshold', () {
      final farUser = const LatLng(36.9000, -2.5200);

      final options = TouristBusRoutePlanner.findNearbyStops(
        place: place,
        allStops: line.stops,
        allLines: [line],
        userLocation: farUser,
        maxDistanceMeters: 2000,
        maxWalkToBoardMeters: 500,
      );

      expect(options, isEmpty);
    });
  });
}
