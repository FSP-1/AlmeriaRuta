import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'line_models.dart';
import '../../core/constants/app_constants.dart';

class BusApiService {
  static final http.Client _client = http.Client();

  static List<LineModel>? _linesCache;
  static Future<List<LineModel>>? _inFlightLines;
  static final Map<String, List<StopModel>> _stopsCache = {};
  static final Map<String, Future<List<StopModel>>> _inFlightStops = {};
  static final Map<String, Map<String, int>> _lineArrivalsCache = {};
  static final Map<String, DateTime> _lineArrivalsFetchedAt = {};
  static final Map<String, Future<Map<String, int>>> _inFlightLineArrivals = {};

  Future<List<LineModel>> getLines({bool forceRefresh = false}) async {
    if (!forceRefresh && _linesCache != null) {
      return _linesCache!;
    }

    if (!forceRefresh && _inFlightLines != null) {
      return _inFlightLines!;
    }

    final future = _fetchLines();
    _inFlightLines = future;
    try {
      final lines = await future;
      _linesCache = lines;
      return lines;
    } finally {
      _inFlightLines = null;
    }
  }

  Future<List<StopModel>> getLineStops(String lineId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _stopsCache.containsKey(lineId)) {
      return _stopsCache[lineId]!;
    }

    if (!forceRefresh && _inFlightStops.containsKey(lineId)) {
      return _inFlightStops[lineId]!;
    }

    final future = _fetchStops(lineId);
    _inFlightStops[lineId] = future;
    try {
      final stops = await future;
      _stopsCache[lineId] = stops;
      return stops;
    } finally {
      _inFlightStops.remove(lineId);
    }
  }

  Future<Map<String, int>> getLineArrivals(String lineId, {bool forceRefresh = false}) async {
    final fetchedAt = _lineArrivalsFetchedAt[lineId];
    final isFresh =
        fetchedAt != null && DateTime.now().difference(fetchedAt).inSeconds < 30;

    if (!forceRefresh && isFresh && _lineArrivalsCache.containsKey(lineId)) {
      return _lineArrivalsCache[lineId]!;
    }

    if (!forceRefresh && _inFlightLineArrivals.containsKey(lineId)) {
      return _inFlightLineArrivals[lineId]!;
    }

    final future = _fetchLineArrivals(lineId);
    _inFlightLineArrivals[lineId] = future;
    try {
      final arrivals = await future;
      _lineArrivalsCache[lineId] = arrivals;
      _lineArrivalsFetchedAt[lineId] = DateTime.now();
      return arrivals;
    } finally {
      _inFlightLineArrivals.remove(lineId);
    }
  }

  Future<Map<String, int>> getStopArrivals(String stopId, {int limit = 3}) async {
    final response = await _getWithRetry(
      Uri.parse('${AppConstants.apiBaseUrl}/stops/$stopId/arrivals?limit=$limit'),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar tiempos de llegada por parada');
    }

    final data = json.decode(response.body);
    if (data is! List) {
      return <String, int>{};
    }

    final result = <String, int>{};
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final lineId = item['lineId']?.toString();
        final minutes = item['minutes'];
        if (lineId != null && minutes is num) {
          result[lineId] = minutes.toInt();
        }
      }
    }
    return result;
  }

  Future<List<LineModel>> _fetchLines() async {
    final response = await _getWithRetry(Uri.parse('${AppConstants.apiBaseUrl}/lines'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => LineModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar lineas');
  }

  Future<List<StopModel>> _fetchStops(String lineId) async {
    final response = await _getWithRetry(
      Uri.parse('${AppConstants.apiBaseUrl}/lines/$lineId/stops'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => StopModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar paradas');
  }

  Future<Map<String, int>> _fetchLineArrivals(String lineId) async {
    final response = await _getWithRetry(
      Uri.parse('${AppConstants.apiBaseUrl}/lines/$lineId/arrivals'),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar tiempos de llegada');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final arrivals = (data['arrivals'] as List<dynamic>? ?? const []);

    final result = <String, int>{};
    for (final item in arrivals) {
      if (item is Map<String, dynamic>) {
        final stopId = item['stopId']?.toString();
        final minutes = item['minutes'];
        if (stopId != null && minutes is num) {
          result[stopId] = minutes.toInt();
        }
      }
    }
    return result;
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    const attempts = 2;
    Object? lastError;

    for (var i = 0; i < attempts; i++) {
      try {
        return await _client.get(uri).timeout(const Duration(seconds: 12));
      } on http.ClientException catch (e) {
        lastError = e;
      } on SocketException catch (e) {
        lastError = e;
      } on HttpException catch (e) {
        lastError = e;
      } on TimeoutException catch (e) {
        lastError = e;
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    throw Exception('Error de red en $uri: $lastError');
  }
}