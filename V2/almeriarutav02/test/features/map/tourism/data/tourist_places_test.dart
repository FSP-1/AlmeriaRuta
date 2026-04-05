import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/map/tourism/data/tourist_places.dart';
import 'package:almeriarutav02/features/map/tourism/models/tourist_place.dart';

void main() {
  group('TouristData.places', () {
    test('contains seeded places and unique ids', () {
      final places = TouristData.places;

      expect(places, isNotEmpty);
      expect(places.length, greaterThan(10));

      final ids = places.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('includes representative categories for filters', () {
      final categories = TouristData.places.map((p) => p.category).toSet();

      expect(categories, contains(TouristCategory.monument));
      expect(categories, contains(TouristCategory.beach));
      expect(categories, contains(TouristCategory.museum));
      expect(categories, contains(TouristCategory.shopping));
      expect(categories, contains(TouristCategory.port));
    });
  });
}
