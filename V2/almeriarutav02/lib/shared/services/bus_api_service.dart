import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'line_models.dart';
import '../../core/constants/app_constants.dart';

class BusApiService {
  static final http.Client _client = http.Client();
  static const Duration _staticDataCacheTtl = Duration(hours: 24);
  // Bump cache keys whenever the static payload/schema changes.
  static const String _linesCacheKey = 'bus_lines_cache_v2';
  static const String _stopsCacheKey = 'bus_stops_cache_v2';
  static const String _staticCacheUpdatedAtKey = 'bus_static_cache_updated_at_v2';

  static List<LineModel>? _linesCache;
  static final Map<String, List<StopModel>> _stopsCache = {};
  static bool _diskCacheLoaded = false;
  static Future<void>? _inFlightDiskCacheLoad;
  static final Map<String, Future<List<StopModel>>> _inFlightStops = {};
  static final Map<String, Map<String, int>> _lineArrivalsCache = {};
  static final Map<String, DateTime> _lineArrivalsFetchedAt = {};
  static final Map<String, Future<Map<String, int>>> _inFlightLineArrivals = {};

Future<List<LineModel>> getLines({bool forceRefresh = false}) async {
  if (_linesCache != null && !forceRefresh) {
  return _linesCache!;
}
  await _ensureDiskCacheLoaded();

  final lines = await _fetchLines();

  //  FIX: construir lineIds reales
  final Map<String, Set<String>> stopToLines = {};

  for (final line in lines) {
    for (final stop in line.stops) {
      stopToLines.putIfAbsent(stop.id, () => {}).add(line.id);
    }
  }

  //  aplicar a cada stop
  final enrichedLines = lines.map((line) {
    final newStops = line.stops.map((s) {
      return s.copyWith(
        lineIds: stopToLines[s.id] ?? {},
      );
    }).toList();

    final newRoutes = line.routes.map((route) {
      final updatedStops = route.stops
          .map((s) => s.copyWith(lineIds: stopToLines[s.id] ?? {}))
          .toList();
      return LineRouteModel(name: route.name, stops: updatedStops);
    }).toList();

    return LineModel(
      id: line.id,
      name: line.name,
      fullName: line.fullName,
      description: line.description,
      color: line.color,
      frequency: line.frequency,
      firstService: line.firstService,
      lastService: line.lastService,
      totalStops: line.totalStops,
      routes: newRoutes,
      stops: newStops,
    );
  }).toList();

  _linesCache = enrichedLines;
  await _persistStaticCaches();

  return enrichedLines;
}

  Future<List<StopModel>> getLineStops(String lineId, {bool forceRefresh = false}) async {
    await _ensureDiskCacheLoaded();

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
      await _persistStaticCaches();
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

  Future<Map<String, int>> getStopArrivals(
    String stopId, {
    int limit = 3,
    String? lineId,
  }) async {
    final query = lineId == null || lineId.isEmpty
        ? 'limit=$limit'
        : 'limit=$limit&lineId=$lineId';

    final response = await _getWithRetry(
      Uri.parse('${AppConstants.apiBaseUrl}/stops/$stopId/arrivals?$query'),
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
      if (data.isNotEmpty && data.first is Map<String, dynamic> && (data.first as Map<String, dynamic>).containsKey('stops')) {
        return data
            .whereType<Map<String, dynamic>>()
            .expand((route) => (route['stops'] as List? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(StopModel.fromJson))
            .toList();
      }
      return data.whereType<Map<String, dynamic>>().map(StopModel.fromJson).toList();
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

  Future<void> _ensureDiskCacheLoaded() async {
    if (_diskCacheLoaded) return;

    if (_inFlightDiskCacheLoad != null) {
      await _inFlightDiskCacheLoad;
      return;
    }

    final future = _loadStaticCachesFromDisk();
    _inFlightDiskCacheLoad = future;
    try {
      await future;
    } finally {
      _inFlightDiskCacheLoad = null;
    }
  }

  Future<void> _loadStaticCachesFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedAtMs = prefs.getInt(_staticCacheUpdatedAtKey);

      if (updatedAtMs != null) {
        final updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMs);
        final isExpired = DateTime.now().difference(updatedAt) > _staticDataCacheTtl;
        if (isExpired) {
          await prefs.remove(_linesCacheKey);
          await prefs.remove(_stopsCacheKey);
          await prefs.remove(_staticCacheUpdatedAtKey);
        }
      }

      final linesRaw = prefs.getString(_linesCacheKey);
      if (linesRaw != null && linesRaw.isNotEmpty) {
        final parsed = json.decode(linesRaw);
        if (parsed is List) {
          _linesCache = parsed
              .whereType<Map<String, dynamic>>()
              .map(LineModel.fromJson)
              .toList();
        }
      }

      final stopsRaw = prefs.getString(_stopsCacheKey);
      if (stopsRaw != null && stopsRaw.isNotEmpty) {
        final parsed = json.decode(stopsRaw);
        if (parsed is Map<String, dynamic>) {
          _stopsCache.clear();
          for (final entry in parsed.entries) {
            final value = entry.value;
            if (value is List) {
              _stopsCache[entry.key] = value
                  .whereType<Map<String, dynamic>>()
                  .map(StopModel.fromJson)
                  .toList();
            }
          }
        }
      }
    } catch (_) {
      // Si falla la lectura del cache persistente seguimos con cache en memoria/red.
    } finally {
      _diskCacheLoaded = true;
    }
  }

  Future<void> _persistStaticCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_linesCache != null) {
        final linesJson = _linesCache!.map((line) => line.toJson()).toList();
        await prefs.setString(_linesCacheKey, json.encode(linesJson));
      }

      final stopsJson = _stopsCache.map(
        (lineId, stops) => MapEntry(
          lineId,
          stops.map((stop) => stop.toJson()).toList(),
        ),
      );
      await prefs.setString(_stopsCacheKey, json.encode(stopsJson));
      await prefs.setInt(
        _staticCacheUpdatedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // El cache en disco es una optimizacion: ignorar errores de persistencia.
    }
  }
}
