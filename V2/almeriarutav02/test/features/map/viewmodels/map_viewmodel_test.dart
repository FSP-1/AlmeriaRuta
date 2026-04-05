import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:almeriarutav02/features/map/models/filter_mode.dart';
import 'package:almeriarutav02/features/map/models/location_model.dart';
import 'package:almeriarutav02/features/map/models/zone_model.dart';
import 'package:almeriarutav02/features/map/tourism/models/tourist_place.dart';
import 'package:almeriarutav02/features/map/viewmodels/map_viewmodel.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';

void main() {
  group('MapViewModel', () {
    test('starts with expected defaults', () {
      final vm = MapViewModel();

      expect(vm.currentFilter.mode, FilterMode.nearby);
      expect(vm.filteredStops, isEmpty);
      expect(vm.isLoadingStops, isFalse);
      expect(vm.activeZone, isNull);
    });

    test('setFilter updates current filter', () {
      final vm = MapViewModel();

      vm.setFilter(const MapFilter.all());

      expect(vm.currentFilter.mode, FilterMode.all);
    });

    test('clearZoneFilter clears active zone', () {
      final vm = MapViewModel();
      final zone = ZoneModel(
        id: 'z1',
        name: 'Zona test',
        polygon: const [
          LatLng(36.0, -2.5),
          LatLng(36.1, -2.5),
          LatLng(36.1, -2.4),
          LatLng(36.0, -2.4),
        ],
        center: const LatLng(36.05, -2.45),
        description: 'test',
      );

      vm.setActiveZone(zone);
      expect(vm.activeZone, isNotNull);

      vm.clearZoneFilter();
      expect(vm.activeZone, isNull);
    });

    test('distance and walking time return placeholder when user location is unavailable', () {
      final vm = MapViewModel();
      final stop = StopModel(
        id: '100',
        name: 'Parada',
        lat: 36.84,
        lon: -2.45,
        zone: 'A',
      );

      expect(vm.calculateDistance(stop), '---');
      expect(vm.calculateWalkingTime(stop), '---');
      expect(vm.calculateDistanceToPoint(const LatLng(36.84, -2.45)), '---');
      expect(vm.calculateWalkingTimeToPoint(const LatLng(36.84, -2.45)), '---');
    });

    test('focusStopFromExternal sets target and line filter', () {
      final vm = MapViewModel();
      final stop = StopModel(
        id: '100',
        name: 'Parada',
        lat: 36.84,
        lon: -2.45,
        zone: 'A',
        lineIds: const {'L1'},
      );

      vm.focusStopFromExternal(stop, lineId: 'L1');

      expect(vm.targetStop?.id, '100');
      expect(vm.currentFilter.mode, FilterMode.line);
      expect(vm.currentFilter.lineId, 'L1');
    });

    test('setRoute and clearRoute update route-related state', () {
      final vm = MapViewModel();
      final stop = StopModel(
        id: '100',
        name: 'Parada',
        lat: 36.84,
        lon: -2.45,
        zone: 'A',
      );
      const route = [LatLng(36.84, -2.45), LatLng(36.85, -2.44)];

      vm.setRoute(stop, route);
      expect(vm.targetStop?.id, '100');
      expect(vm.activeRoute, route);
      expect(vm.selectedTouristPlace, isNull);

      vm.clearRoute();
      expect(vm.targetStop, isNull);
      expect(vm.activeRoute, isEmpty);
      expect(vm.routeDistanceMeters, 0);
      expect(vm.routeDurationMinutes, 0);
    });

    test('setSelectedLocation + clearSelection reset legacy selection state', () {
      final vm = MapViewModel();
      final location = LocationModel(
        latitude: 36.84,
        longitude: -2.45,
        address: 'Centro',
        name: 'Centro',
      );

      vm.setSelectedLocation(location);
      expect(vm.selectedLocation, isNotNull);

      vm.clearSelection();
      expect(vm.selectedLocation, isNull);
      expect(vm.selectedZone, isNull);
      expect(vm.errorMessage, isNull);
    });

    test('setLoading and error helpers mutate expected flags', () {
      final vm = MapViewModel();

      vm.setLoading(true);
      expect(vm.isLoading, isTrue);

      vm.setError('boom');
      expect(vm.errorMessage, 'boom');
      expect(vm.isLoading, isFalse);

      vm.clearError();
      expect(vm.errorMessage, isNull);
    });

    test('setSelectedZone + updateStopsForZone filters and counts lines in polygon', () {
      final vm = MapViewModel();
      final zone = ZoneModel(
        id: 'z1',
        name: 'Zona test',
        polygon: const [
          LatLng(36.80, -2.50),
          LatLng(36.80, -2.40),
          LatLng(36.90, -2.40),
          LatLng(36.90, -2.50),
        ],
        center: const LatLng(36.85, -2.45),
        description: 'zona test',
      );

      vm.setSelectedZone(zone);
      vm.updateStopsForZone([
        StopModel(
          id: '100',
          name: 'Dentro 1',
          lat: 36.84,
          lon: -2.46,
          zone: 'A',
          lineIds: const {'L1', 'L2'},
        ),
        StopModel(
          id: '101',
          name: 'Dentro 2',
          lat: 36.83,
          lon: -2.47,
          zone: 'A',
          lineIds: const {'L1'},
        ),
        StopModel(
          id: '102',
          name: 'Fuera',
          lat: 36.70,
          lon: -2.47,
          zone: 'A',
          lineIds: const {'L3'},
        ),
      ]);

      expect(vm.stopsInZone.map((s) => s.id), containsAll(['100', '101']));
      expect(vm.stopsInZone.map((s) => s.id), isNot(contains('102')));
      expect(vm.linesInZone['L1'], 2);
      expect(vm.linesInZone['L2'], 1);
    });

    test('updateStopsForZone clears zone aggregates when selected zone is null', () {
      final vm = MapViewModel();

      vm.updateStopsForZone([
        StopModel(
          id: '100',
          name: 'Parada',
          lat: 36.84,
          lon: -2.46,
          zone: 'A',
          lineIds: const {'L1'},
        ),
      ]);

      expect(vm.stopsInZone, isEmpty);
      expect(vm.linesInZone, isEmpty);
    });

    test('setTouristRoute sets route metrics and fallback flag', () {
      final vm = MapViewModel();
      final place = TouristPlace(
        id: 'tp1',
        name: 'Alcazaba',
        location: const LatLng(36.841, -2.467),
        description: 'Monumento',
        category: TouristCategory.monument,
      );

      const result = RouteResult(
        points: [LatLng(36.838, -2.460), LatLng(36.841, -2.467)],
        distanceMeters: 700,
        durationMinutes: 9,
        isFallback: true,
      );

      vm.setTouristRoute(place, result);

      expect(vm.targetStop, isNull);
      expect(vm.selectedTouristPlace?.id, 'tp1');
      expect(vm.activeRoute, result.points);
      expect(vm.routeDistanceMeters, 700);
      expect(vm.routeDurationMinutes, 9);
      expect(vm.isRouteFallback, isTrue);
    });
  });
}
