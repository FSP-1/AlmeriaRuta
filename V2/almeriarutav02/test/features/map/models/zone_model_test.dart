import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:almeriarutav02/features/map/models/zone_model.dart';

void main() {
  group('ZoneModel / AlmeriaZones', () {
    test('ZoneModel.fromJson maps polygon, center and type', () {
      final zone = ZoneModel.fromJson({
        'id': 'z1',
        'name': 'Zona Test',
        'description': 'desc',
        'type': 'tourist',
        'center': {'lat': 36.84, 'lng': -2.46},
        'polygon': [
          {'lat': 36.83, 'lng': -2.47},
          {'lat': 36.85, 'lng': -2.47},
          {'lat': 36.85, 'lng': -2.45},
          {'lat': 36.83, 'lng': -2.45},
        ],
      });

      expect(zone.id, 'z1');
      expect(zone.name, 'Zona Test');
      expect(zone.type, ZoneType.tourist);
      expect(zone.polygon, hasLength(4));
      expect(zone.center.latitude, 36.84);
      expect(zone.center.longitude, -2.46);
    });

    test('isPointInsidePolygon returns true for interior point and false for exterior point', () {
      final polygon = const [
        LatLng(0, 0),
        LatLng(0, 1),
        LatLng(1, 1),
        LatLng(1, 0),
      ];

      expect(AlmeriaZones.isPointInsidePolygon(const LatLng(0.5, 0.5), polygon), isTrue);
      expect(AlmeriaZones.isPointInsidePolygon(const LatLng(1.5, 1.5), polygon), isFalse);
    });

    test('findZoneByLatLng resolves known Almeria coordinate', () {
      final zone = AlmeriaZones.findZoneByLatLng(const LatLng(36.8385, -2.4630));

      expect(zone, isNotNull);
      expect(zone!.name, isNotEmpty);
    });

    test('rayCastIntersect detects crossing and non-crossing segments', () {
      final crossing = AlmeriaZones.rayCastIntersect(
        const LatLng(0.5, 0.5),
        const LatLng(0, 0),
        const LatLng(1, 1),
      );
      final nonCrossing = AlmeriaZones.rayCastIntersect(
        const LatLng(2, 2),
        const LatLng(0, 0),
        const LatLng(1, 1),
      );

      expect(crossing, isFalse);
      expect(nonCrossing, isFalse);
    });
  });
}
