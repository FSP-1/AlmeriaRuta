import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../../shared/services/bus_api_service.dart';
import '../../../shared/services/line_models.dart';
import '../../map/models/zone_model.dart';
import '../models/stop_popup_model.dart';

class LinesViewModel extends ChangeNotifier {
  final BusApiService _apiService = BusApiService();

  List<LineModel> _lines = [];
  final Map<String, List<StopModel>> _lineStopsCache = {};
  final Map<String, Set<String>> _stopToLineIds = {};
  final Map<String, Map<String, int>> _arrivalsByLine = {};
  final Set<String> _watchedLines = {};
  Timer? _clockTimer;
  bool _isLoading = false;
  String? _error;

  List<LineModel> get lines => _lines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLines({bool forceRefresh = false}) async {
    _ensureClockRunning();

    if (!forceRefresh && (_isLoading || _lines.isNotEmpty)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lines = await _apiService.getLines(forceRefresh: forceRefresh);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _ensureClockRunning() {
    _clockTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      for (final lineId in _watchedLines) {
        ensureLineArrivals(lineId, forceRefresh: true);
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<List<StopModel>> getLineStops(String lineId) async {
    final cached = _lineStopsCache[lineId];
    if (cached != null) {
      return cached;
    }

    final stops = await _apiService.getLineStops(lineId);
    _lineStopsCache[lineId] = stops;

    for (final stop in stops) {
      final ids = _stopToLineIds.putIfAbsent(stop.id, () => <String>{});
      ids.add(lineId);
    }

    return stops;
  }

  Future<void> ensureLineArrivals(String lineId, {bool forceRefresh = false}) async {
    _watchedLines.add(lineId);
    try {
      final arrivals = await _apiService.getLineArrivals(
        lineId,
        forceRefresh: forceRefresh,
      );
      _arrivalsByLine[lineId] = arrivals;
      notifyListeners();
    } catch (_) {}
  }

  int? getArrivalMinutes(String lineId, String stopId) {
    return _arrivalsByLine[lineId]?[stopId];
  }

  String formatArrivalLabel(int? minutes) {
    if (minutes == null) return '--';
    if (minutes <= 1) return 'Llegando';
    if (minutes <= 3) return 'Inminente';
    return '$minutes min';
  }

  Future<Map<String, int>> fetchStopArrivals(
    String stopId, {
    int limit = 10,
    String? lineId,
  }) {
    return _apiService.getStopArrivals(
      stopId,
      limit: limit,
      lineId: lineId,
    );
  }

  Future<List<LineModel>> getLinesPassingStop(StopModel stop, LineModel currentLine) async {
    final lineIds = _stopToLineIds[stop.id];

    if (lineIds != null && lineIds.isNotEmpty) {
      final results = _lines.where((line) => lineIds.contains(line.id)).toList();
      if (results.isNotEmpty) {
        return results;
      }
    }

    final ids = <String>{currentLine.id};

    for (final line in _lines) {
      if (line.id == currentLine.id) continue;
      final stops = await getLineStops(line.id);
      final exists = stops.any((s) => s.id == stop.id);
      if (exists) {
        ids.add(line.id);
      }
    }

    return _lines.where((line) => ids.contains(line.id)).toList();
  }

  Future<StopPopupModel> buildStopPopupData(
    StopModel stop,
    LineModel currentLine, {
    List<StopModel>? aggregatedStops,
  }) async {
    final passingLines = aggregatedStops != null && aggregatedStops.isNotEmpty
        ? resolveLinesPassingStopUsingMapData(stop, currentLine, aggregatedStops)
        : await getLinesPassingStop(stop, currentLine);
    final zone = AlmeriaZones.findZoneByLatLng(
      LatLng(stop.lat, stop.lon),
    );

    return StopPopupModel(
      stop: stop,
      zoneName: zone?.name ?? 'Sin zona definida',
      passingLines: passingLines,
    );
  }

  List<LineModel> resolveLinesPassingStopUsingMapData(
    StopModel stop,
    LineModel currentLine,
    List<StopModel> aggregatedStops,
  ) {
    return _resolveLinesWithAggregatedStops(
      stop: stop,
      currentLine: currentLine,
      aggregatedStops: aggregatedStops,
    );
  }

  List<LineModel> _resolveLinesWithAggregatedStops({
    required StopModel stop,
    required LineModel currentLine,
    required List<StopModel> aggregatedStops,
  }) {
    final byId = aggregatedStops.where((s) => s.id == stop.id).toList();
    StopModel? matched = byId.isNotEmpty ? byId.first : null;

    if (matched == null) {
      const distance = Distance();
      final nearByName = aggregatedStops.where((s) {
        if (s.name.trim().toLowerCase() != stop.name.trim().toLowerCase()) {
          return false;
        }
        final meters = distance.as(
          LengthUnit.Meter,
          LatLng(s.lat, s.lon),
          LatLng(stop.lat, stop.lon),
        );
        return meters <= 60;
      }).toList();
      if (nearByName.isNotEmpty) {
        matched = nearByName.first;
      }
    }

    if (matched == null || matched.lineIds.isEmpty) {
      return [currentLine];
    }

    final ids = <String>{...matched.lineIds, currentLine.id};
    final lines = _lines.where((line) => ids.contains(line.id)).toList();
    if (lines.isEmpty) {
      return [currentLine];
    }
    return lines;
  }
}
