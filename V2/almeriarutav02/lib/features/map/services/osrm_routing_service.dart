import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final int durationMinutes;
  final bool isFallback;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationMinutes,
    required this.isFallback,
  });
}

class OsrmRoutingService {
  static const double _walkingSpeedMps = 1.39;
  static const double _maxReasonableWalkingSpeedMps = 2.2;

  Future<RouteResult> getRoute(LatLng from, LatLng to, {String profile = 'walking'}) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$profile/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) throw Exception('OSRM error');

      final data = json.decode(response.body);
      final route = data['routes'][0];
      final coords = route['geometry']['coordinates'] as List;
      final distanceMeters = (route['distance'] as num?)?.toDouble() ??
          _straightLine(from, to);
      final osrmDurationSeconds =
          (route['duration'] as num?)?.toDouble() ?? (distanceMeters / _walkingSpeedMps);
      final osrmSpeedMps = distanceMeters / osrmDurationSeconds;
      final durationMinutes = osrmSpeedMps > _maxReasonableWalkingSpeedMps
          ? walkMinutes(distanceMeters)
          : (osrmDurationSeconds / 60).round();

      return RouteResult(
        points: coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList(),
        distanceMeters: distanceMeters,
        durationMinutes: durationMinutes,
        isFallback: false,
      );
    } catch (_) {
      final d = _straightLine(from, to);
      return RouteResult(
        points: [from, to],
        distanceMeters: d,
        durationMinutes: walkMinutes(d),
        isFallback: true,
      );
    }
  }

  Future<List<LatLng>> getSegmentPoints(LatLng from, LatLng to, {String profile = 'walking'}) async {
    final result = await getRoute(from, to, profile: profile);
    return result.points;
  }

  static double _straightLine(LatLng from, LatLng to) =>
      Geolocator.distanceBetween(from.latitude, from.longitude, to.latitude, to.longitude);

  static int walkMinutes(double meters) {
    final m = ((meters / _walkingSpeedMps) / 60).round();
    return (meters > 0 && m == 0) ? 1 : m;
  }
}
