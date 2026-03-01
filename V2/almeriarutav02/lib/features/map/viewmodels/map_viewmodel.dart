import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/location_model.dart';
import '../models/zone_model.dart';
import '../models/filter_mode.dart';
import '../models/favorite_model.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/bus_api_service.dart';

class MapViewModel extends ChangeNotifier {
  final BusApiService _apiService = BusApiService();
  
  // Estado de negocio
  List<StopModel> _stops = [];
  List<LineModel> _lines = [];
  LatLng? _userLocation;
  MapFilter _currentFilter = const MapFilter.nearby();
  Set<String> _favoriteStopIds = <String>{};
  
  // Estado de UI
  bool _isLoadingStops = false;
  
  // Legacy properties (mantener compatibilidad)
  LocationModel? _selectedLocation;
  ZoneModel? _selectedZone;
  StopModel? _targetStop;
  List<LatLng> _activeRoute = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<StopModel> _stopsInZone = [];
  Map<String, int> _linesInZone = {};

  // Getters - Estado de negocio
  List<StopModel> get stops => _stops;
  List<StopModel> get filteredStops => _getFilteredStops();
  List<LineModel> get lines => _lines;
  LatLng? get userLocation => _userLocation;
  MapFilter get currentFilter => _currentFilter;
  bool get isLoadingStops => _isLoadingStops;
  Set<String> get favoriteStopIds => _favoriteStopIds;
  
  // Legacy getters
  LocationModel? get selectedLocation => _selectedLocation;
  ZoneModel? get selectedZone => _selectedZone;
  StopModel? get targetStop => _targetStop;
  List<LatLng> get activeRoute => _activeRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<StopModel> get stopsInZone => _stopsInZone;
  Map<String, int> get linesInZone => _linesInZone;

  // Inicialización
  Future<void> initialize() async {
    await loadStops();
    await getCurrentLocation();
    await refreshFavoriteStops();
  }

  Future<void> refreshFavoriteStops() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('favorites') ?? [];
    final favoriteStops = <String>{};

    for (final item in data) {
      try {
        final fav = FavoriteModel.fromJson(json.decode(item));
        if (fav.type == FavoriteType.stop) {
          favoriteStops.add(fav.id);
        }
      } catch (_) {}
    }

    _favoriteStopIds = favoriteStops;

    if (_currentFilter.mode == FilterMode.favorites && _favoriteStopIds.isEmpty) {
      _currentFilter = const MapFilter.nearby();
    }

    notifyListeners();
  }

  // Cargar paradas desde API
  Future<void> loadStops() async {
    _isLoadingStops = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final lines = await _apiService.getLines();
      final uniqueStops = <String, StopModel>{};
      
      for (final line in lines) {
        final stops = await _apiService.getLineStops(line.id);
        
        for (final stop in stops) {
          if (uniqueStops.containsKey(stop.id)) {
            uniqueStops[stop.id] = uniqueStops[stop.id]!.copyWith(
              lineIds: {...uniqueStops[stop.id]!.lineIds, line.id},
            );
          } else {
            uniqueStops[stop.id] = stop.copyWith(
              lineIds: {line.id},
            );
          }
        }
      }
      
      _lines = lines;
      _stops = uniqueStops.values.toList();
      
      // Asegurar que inicia con paradas cercanas si hay ubicación
      if (_userLocation != null) {
        _currentFilter = const MapFilter.nearby();
      }
      
      _isLoadingStops = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar paradas: $e';
      _isLoadingStops = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener ubicación del usuario
  Future<void> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      _userLocation = LatLng(position.latitude, position.longitude);
      
      // Si ya cargó paradas, actualizar filtro a nearby
      if (_stops.isNotEmpty) {
        _currentFilter = const MapFilter.nearby();
      }
      
      notifyListeners();
    } catch (e) {
      // Si falla, usar ubicación por defecto de Almería
      _userLocation = const LatLng(36.8381, -2.4597);
      notifyListeners();
    }
  }

  // Filtrado de paradas
  List<StopModel> _getFilteredStops() {
    switch (_currentFilter.mode) {
      case FilterMode.nearby:
        if (_userLocation == null) return _stops;
        return _stops.where((stop) {
          final distance = Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            stop.lat,
            stop.lon,
          );
          return distance <= 800; // 800 metros
        }).toList();
        
      case FilterMode.all:
        return _stops;

      case FilterMode.favorites:
        if (_favoriteStopIds.isEmpty) return [];
        return _stops.where((stop) => _favoriteStopIds.contains(stop.id)).toList();
        
      case FilterMode.line:
        if (_currentFilter.lineId == null) return _stops;
        return _stops.where(
          (stop) => stop.lineIds.contains(_currentFilter.lineId)
        ).toList();
    }
  }

  // Cambiar filtro
  void setFilter(MapFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // Obtener ruta entre dos puntos
  Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/walking/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Error getting route');
      }

      final data = json.decode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;

      return coords.map((c) => LatLng(c[1], c[0])).toList();
    } catch (e) {
      // Si falla, retornar línea recta
      return [from, to];
    }
  }

  // Calcular distancia a una parada
  String calculateDistance(StopModel stop) {
    if (_userLocation == null) return '---';
    
    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      stop.lat,
      stop.lon,
    );
    
    return distance.round().toString();
  }

  // Calcular tiempo caminando a una parada
  String calculateWalkingTime(StopModel stop) {
    if (_userLocation == null) return '---';
    
    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      stop.lat,
      stop.lon,
    );
    
    // Velocidad promedio caminando: 5 km/h = 1.39 m/s
    final timeInSeconds = distance / 1.39;
    final timeInMinutes = (timeInSeconds / 60).round();
    
    return timeInMinutes.toString();
  }

  // Legacy methods (mantener compatibilidad)
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
