import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/map/models/location_model.dart';

void main() {
  group('LocationModel', () {
    test('fromJson parses numeric fields and optional name', () {
      final location = LocationModel.fromJson({
        'lat': 36.84,
        'lon': -2.46,
        'display_name': 'Centro, Almería',
        'name': 'Centro',
      });

      expect(location.latitude, 36.84);
      expect(location.longitude, -2.46);
      expect(location.address, 'Centro, Almería');
      expect(location.name, 'Centro');
    });

    test('fromJson applies defaults on missing values', () {
      final location = LocationModel.fromJson({});

      expect(location.latitude, 0.0);
      expect(location.longitude, 0.0);
      expect(location.address, '');
      expect(location.name, isNull);
    });
  });
}
