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

// Zonas generales urbanas de Almeria Capital
class AlmeriaZones {
  static final List<ZoneModel> zones = [
    ZoneModel(
      id: 'centro',
      name: 'Centro',
      description: 'Centro historico, Rambla, Paseo de Almeria',
      type: ZoneType.transport,
      center: const LatLng(36.8385, -2.4630),
      polygon: const [
        LatLng(36.845, -2.475),
        LatLng(36.845, -2.450),
        LatLng(36.830, -2.450),
        LatLng(36.830, -2.475),
      ],
    ),
    ZoneModel(
      id: 'playa',
      name: 'Zona Playa',
      description: 'Zapillo, Paseo Maritimo, Nueva Almeria',
      type: ZoneType.transport,
      center: const LatLng(36.8290, -2.4400),
      polygon: const [
        LatLng(36.835, -2.455),
        LatLng(36.835, -2.420),
        LatLng(36.820, -2.420),
        LatLng(36.820, -2.455),
      ],
    ),
    ZoneModel(
      id: 'norte',
      name: 'Zona Norte',
      description: 'Torrecardenas, Hospital, barrios del norte',
      type: ZoneType.transport,
      center: const LatLng(36.8600, -2.4450),
      polygon: const [
        LatLng(36.880, -2.470),
        LatLng(36.880, -2.420),
        LatLng(36.845, -2.420),
        LatLng(36.845, -2.470),
      ],
    ),
    ZoneModel(
      id: 'oeste',
      name: 'Zona Oeste',
      description: 'Los Angeles, Nueva Andalucia, Carrefour',
      type: ZoneType.transport,
      center: const LatLng(36.8450, -2.4750),
      polygon: const [
        LatLng(36.860, -2.500),
        LatLng(36.860, -2.460),
        LatLng(36.830, -2.460),
        LatLng(36.830, -2.500),
      ],
    ),
    ZoneModel(
      id: 'este',
      name: 'Zona Este',
      description: 'Vega de Aca, expansion moderna',
      type: ZoneType.transport,
      center: const LatLng(36.8350, -2.4350),
      polygon: const [
        LatLng(36.850, -2.450),
        LatLng(36.850, -2.410),
        LatLng(36.820, -2.410),
        LatLng(36.820, -2.450),
      ],
    ),
    ZoneModel(
      id: 'pescaderia',
      name: 'Pescaderia / La Chanca',
      description: 'Zona historica junto al puerto',
      type: ZoneType.transport,
      center: const LatLng(36.8405, -2.4700),
      polygon: const [
        LatLng(36.850, -2.480),
        LatLng(36.850, -2.460),
        LatLng(36.830, -2.460),
        LatLng(36.830, -2.480),
      ],
    ),
    ZoneModel(
      id: 'universidad',
      name: 'La Canada / Universidad',
      description: 'UAL y alrededores',
      type: ZoneType.transport,
      center: const LatLng(36.8295, -2.4050),
      polygon: const [
        LatLng(36.845, -2.420),
        LatLng(36.845, -2.390),
        LatLng(36.815, -2.390),
        LatLng(36.815, -2.420),
      ],
    ),
    ZoneModel(
      id: 'retoyo',
      name: 'Retamar / El Toyo',
      description: 'Zona turistica y hoteles',
      type: ZoneType.transport,
      center: const LatLng(36.8505, -2.3220),
      polygon: const [
        LatLng(36.870, -2.350),
        LatLng(36.870, -2.300),
        LatLng(36.830, -2.300),
        LatLng(36.830, -2.350),
      ],
    ),
    ZoneModel(
      id: 'aeropuerto',
      name: 'Aeropuerto',
      description: 'Aeropuerto de Almeria',
      type: ZoneType.transport,
      center: const LatLng(36.8439, -2.3701),
      polygon: const [
        LatLng(36.855, -2.385),
        LatLng(36.855, -2.355),
        LatLng(36.830, -2.355),
        LatLng(36.830, -2.385),
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