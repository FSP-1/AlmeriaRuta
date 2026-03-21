import 'package:latlong2/latlong.dart';

enum ZoneType {
  transport,
  tourist,
}

class ZoneModel {
  final String id;
  final String name;
  final List<LatLng> polygon;
  final LatLng center;
  final String description;
  final ZoneType type;

  ZoneModel({
    required this.id,
    required this.name,
    required this.polygon,
    required this.center,
    required this.description,
    this.type = ZoneType.transport,
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
      type: ZoneType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'transport'),
        orElse: () => ZoneType.transport,
      ),
    );
  }
}

// Zonas geográficas reales (comarcas y área metropolitana)
class AlmeriaZones {
  static final List<ZoneModel> zones = [
    ZoneModel(
      id: 'capital',
      name: 'Almería Capital',
      description: 'Zona urbana principal de la ciudad de Almería',
      type: ZoneType.transport,
      center: const LatLng(36.8381, -2.4597),
      polygon: const [
        LatLng(36.92, -2.59),
        LatLng(36.92, -2.31),
        LatLng(36.74, -2.31),
        LatLng(36.74, -2.59),
      ],
    ),
    ZoneModel(
      id: 'poniente',
      name: 'Poniente',
      description: 'Comarca general del Poniente almeriense',
      type: ZoneType.transport,
      center: const LatLng(36.76, -2.61),
      polygon: const [
        LatLng(36.95, -2.95),
        LatLng(36.95, -2.52),
        LatLng(36.55, -2.52),
        LatLng(36.55, -2.95),
      ],
    ),
    ZoneModel(
      id: 'levante',
      name: 'Levante',
      description: 'Comarca general del Levante almeriense',
      type: ZoneType.transport,
      center: const LatLng(37.10, -1.85),
      polygon: const [
        LatLng(37.42, -2.25),
        LatLng(37.42, -1.52),
        LatLng(36.90, -1.52),
        LatLng(36.90, -2.25),
      ],
    ),
    ZoneModel(
      id: 'interior',
      name: 'Interior',
      description: 'Zonas del interior de la provincia de Almería',
      type: ZoneType.transport,
      center: const LatLng(37.30, -2.20),
      polygon: const [
        LatLng(37.80, -2.95),
        LatLng(37.80, -1.80),
        LatLng(36.90, -1.80),
        LatLng(36.90, -2.95),
      ],
    ),
  ];

  static bool _isTransportZone(ZoneModel zone) {
    try {
      return zone.type == ZoneType.transport;
    } catch (_) {
      // Backward compatibility with stale runtime objects.
      return true;
    }
  }

  static bool _isTouristZone(ZoneModel zone) {
    try {
      return zone.type == ZoneType.tourist;
    } catch (_) {
      return false;
    }
  }

  static List<ZoneModel> get transportZones =>
      zones.where(_isTransportZone).toList();

  static List<ZoneModel> get touristZones =>
      zones.where(_isTouristZone).toList();

  static ZoneModel? findZoneByLatLng(LatLng point) {
    for (final zone in transportZones) {
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