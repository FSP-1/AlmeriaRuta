import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../models/zone_model.dart';
import '../../../shared/services/line_models.dart';
import 'package:latlong2/latlong.dart';

class MapViewModel extends ChangeNotifier {
  LocationModel? _selectedLocation;
  ZoneModel? _selectedZone;
  StopModel? _targetStop;
  List<LatLng> _activeRoute = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<StopModel> _stopsInZone = [];
  Map<String, int> _linesInZone = {};

  LocationModel? get selectedLocation => _selectedLocation;
  ZoneModel? get selectedZone => _selectedZone;
  StopModel? get targetStop => _targetStop;
  List<LatLng> get activeRoute => _activeRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<StopModel> get stopsInZone => _stopsInZone;
  Map<String, int> get linesInZone => _linesInZone;

  void setSelectedLocation(LocationModel location) {
    _selectedLocation = location;
    _errorMessage = null;
    notifyListeners();
  }

  void setSelectedZone(ZoneModel? zone) {
    _selectedZone = zone;
    _updateStopsInZone();
    notifyListeners();
  }

  void setRoute(StopModel stop, List<LatLng> route) {
    _targetStop = stop;
    _activeRoute = route;
    notifyListeners();
  }

  void clearRoute() {
    _targetStop = null;
    _activeRoute = [];
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedLocation = null;
    _selectedZone = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _updateStopsInZone() {
    if (_selectedZone == null) {
      _stopsInZone = [];
      _linesInZone = {};
      return;
    }

    // Esta función se llamará desde el widget con la lista de paradas
    // Por ahora dejamos vacío
  }

  void updateStopsForZone(List<StopModel> allStops) {
    if (_selectedZone == null) {
      _stopsInZone = [];
      _linesInZone = {};
      return;
    }

    _stopsInZone = allStops.where((stop) {
      return AlmeriaZones.isPointInsidePolygon(
        LatLng(stop.lat, stop.lon),
        _selectedZone!.polygon,
      );
    }).toList();

    // Calcular líneas en proporción
    final counts = <String, int>{};
    for (final stop in _stopsInZone) {
      for (final lineId in stop.lineIds) {
        counts[lineId] = (counts[lineId] ?? 0) + 1;
      }
    }
    _linesInZone = Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );

    notifyListeners();
  }
}