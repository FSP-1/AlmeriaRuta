import 'package:latlong2/latlong.dart';

class ZoneModel {
  final String id;
  final String name;
  final List<LatLng> polygon;
  final LatLng center;
  final String description;

  ZoneModel({
    required this.id,
    required this.name,
    required this.polygon,
    required this.center,
    required this.description,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'],
      name: json['name'],
      polygon: (json['polygon'] as List)
          .map((p) => LatLng(p['lat'], p['lng']))
          .toList(),
      center: LatLng(json['center']['lat'], json['center']['lng']),
      description: json['description'] ?? '',
    );
  }
}

// Zonas predefinidas de Almería
class AlmeriaZones {
  static final List<ZoneModel> zones = [
    ZoneModel(
      id: 'centro',
      name: 'Centro',
      description: 'Centro histórico de Almería',
      center: const LatLng(36.8381, -2.4597),
      polygon: const [
        LatLng(36.845, -2.475),
        LatLng(36.845, -2.445),
        LatLng(36.831, -2.445),
        LatLng(36.831, -2.475),
      ],
    ),
    ZoneModel(
      id: 'zapillo',
      name: 'El Zapillo',
      description: 'Zona costera este',
      center: const LatLng(36.8290, -2.4350),
      polygon: const [
        LatLng(36.835, -2.445),
        LatLng(36.835, -2.425),
        LatLng(36.823, -2.425),
        LatLng(36.823, -2.445),
      ],
    ),
    ZoneModel(
      id: 'torrecardenas',
      name: 'Torrecárdenas',
      description: 'Zona norte - Hospital',
      center: const LatLng(36.8630, -2.4440),
      polygon: const [
        LatLng(36.870, -2.455),
        LatLng(36.870, -2.433),
        LatLng(36.856, -2.433),
        LatLng(36.856, -2.455),
      ],
    ),
    ZoneModel(
      id: 'nueva_almeria',
      name: 'Nueva Almería',
      description: 'Zona oeste moderna',
      center: const LatLng(36.8450, -2.4750),
      polygon: const [
        LatLng(36.855, -2.485),
        LatLng(36.855, -2.465),
        LatLng(36.835, -2.465),
        LatLng(36.835, -2.485),
      ],
    ),
  ];

  static ZoneModel? findZoneByLatLng(LatLng point) {
    for (final zone in zones) {
      if (isPointInsidePolygon(point, zone.polygon)) {
        return zone;
      }
    }
    return null;
  }

  static bool isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      if (rayCastIntersect(point, polygon[j], polygon[j + 1])) {
        intersectCount++;
      }
    }
    return ((intersectCount % 2) == 1);
  }

  static bool rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double aY = vertA.latitude;
    double bY = vertB.latitude;
    double aX = vertA.longitude;
    double bX = vertB.longitude;
    double pY = point.latitude;
    double pX = point.longitude;

    if ((aY > pY) != (bY > pY) &&
        (pX < (bX - aX) * (pY - aY) / (bY - aY) + aX)) {
      return true;
    }
    return false;
  }
}