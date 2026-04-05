import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:almeriarutav02/features/map/tourism/models/tourist_place.dart';

void main() {
  group('TouristPlace', () {
    test('keeps all constructor values', () {
      const place = TouristPlace(
        id: 'tp1',
        name: 'Alcazaba',
        location: LatLng(36.841, -2.467),
        description: 'Monumento historico',
        category: TouristCategory.monument,
      );

      expect(place.id, 'tp1');
      expect(place.name, 'Alcazaba');
      expect(place.location, const LatLng(36.841, -2.467));
      expect(place.description, 'Monumento historico');
      expect(place.category, TouristCategory.monument);
    });

    test('enum contains expected categories', () {
      expect(TouristCategory.values, contains(TouristCategory.beach));
      expect(TouristCategory.values, contains(TouristCategory.museum));
      expect(TouristCategory.values, contains(TouristCategory.leisure));
    });
  });
}
