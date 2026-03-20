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
import '../tourism/models/tourist_place.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/bus_api_service.dart';

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

class MapViewModel extends ChangeNotifier {
  final BusApiService _apiService = BusApiService();
  static const double _walkingSpeedMps = 1.39; // ~5 km/h
  static const double _maxReasonableWalkingSpeedMps = 2.2; // ~7.9 km/h
  
  // Estado de negocio
  List<StopModel> _stops = [];
  List<LineModel> _lines = [];
  LatLng? _userLocation;
  MapFilter _currentFilter = const MapFilter.nearby();
  Set<String> _favoriteStopIds = <String>{};
  ZoneModel? _activeZone;
  
  // Estado de UI
  bool _isLoadingStops = false;
  
  // Legacy properties (mantener compatibilidad)
  LocationModel? _selectedLocation;
  ZoneModel? _selectedZone;
  StopModel? _targetStop;
  TouristPlace? _selectedTouristPlace;
  List<LatLng> _activeRoute = [];
  double _routeDistanceMeters = 0;
  int _routeDurationMinutes = 0;
  bool _isRouteFallback = false;
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
  ZoneModel? get activeZone => _activeZone;
  
  // Legacy getters
  LocationModel? get selectedLocation => _selectedLocation;
  ZoneModel? get selectedZone => _selectedZone;
  StopModel? get targetStop => _targetStop;
  TouristPlace? get selectedTouristPlace => _selectedTouristPlace;
  List<LatLng> get activeRoute => _activeRoute;
  double get routeDistanceMeters => _routeDistanceMeters;
  int get routeDurationMinutes => _routeDurationMinutes;
  bool get isRouteFallback => _isRouteFallback;
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
    List<StopModel> filteredByMode;

    switch (_currentFilter.mode) {
      case FilterMode.nearby:
        if (_userLocation == null) return _stops;
        filteredByMode = _stops.where((stop) {
          final distance = Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            stop.lat,
            stop.lon,
          );
          return distance <= 800; // 800 metros
        }).toList();
        break;
        
      case FilterMode.all:
        filteredByMode = _stops;
        break;

      case FilterMode.favorites:
        filteredByMode = _favoriteStopIds.isEmpty
            ? []
            : _stops.where((stop) => _favoriteStopIds.contains(stop.id)).toList();
        break;
        
      case FilterMode.line:
        filteredByMode = _currentFilter.lineId == null
            ? _stops
            : _stops
                .where((stop) => stop.lineIds.contains(_currentFilter.lineId))
                .toList();
        break;
    }

    if (_activeZone == null) {
      return filteredByMode;
    }

    return filteredByMode.where((stop) {
      return AlmeriaZones.isPointInsidePolygon(
        LatLng(stop.lat, stop.lon),
        _activeZone!.polygon,
      );
    }).toList();
  }

  // Cambiar filtro
  void setFilter(MapFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setActiveZone(ZoneModel? zone) {
    _activeZone = zone;
    notifyListeners();
  }

  void clearZoneFilter() {
    _activeZone = null;
    notifyListeners();
  }

  // Obtener ruta entre dos puntos
  Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    final result = await getRouteResult(from, to);
    return result.points;
  }

  Future<RouteResult> getRouteResult(LatLng from, LatLng to) async {
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
      final route = data['routes'][0];
      final coords = route['geometry']['coordinates'] as List;
      final distanceMeters = (route['distance'] as num?)?.toDouble() ??
          Geolocator.distanceBetween(
            from.latitude,
            from.longitude,
            to.latitude,
            to.longitude,
          );
        final osrmDurationSeconds =
          (route['duration'] as num?)?.toDouble() ?? (distanceMeters / _walkingSpeedMps);
        final osrmSpeedMps = distanceMeters / osrmDurationSeconds;

        // Algunos perfiles devuelven duraciones tipo coche; si pasa, usamos estimacion peatonal.
        final durationMinutes = osrmSpeedMps > _maxReasonableWalkingSpeedMps
          ? _estimateWalkingMinutes(distanceMeters)
          : (osrmDurationSeconds / 60).round();

      return RouteResult(
        points: coords.map((c) => LatLng(c[1], c[0])).toList(),
        distanceMeters: distanceMeters,
        durationMinutes: durationMinutes,
        isFallback: false,
      );
    } catch (e) {
      // Si falla, retornar linea recta como fallback
      final distanceMeters = Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );
      final durationMinutes = _estimateWalkingMinutes(distanceMeters);
      return RouteResult(
        points: [from, to],
        distanceMeters: distanceMeters,
        durationMinutes: durationMinutes,
        isFallback: true,
      );
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
    final timeInMinutes = _estimateWalkingMinutes(distance);
    
    return timeInMinutes.toString();
  }

  String calculateDistanceToPoint(LatLng point) {
    if (_userLocation == null) return '---';

    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      point.latitude,
      point.longitude,
    );

    return distance.round().toString();
  }

  String calculateWalkingTimeToPoint(LatLng point) {
    if (_userLocation == null) return '---';

    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      point.latitude,
      point.longitude,
    );

    final timeInMinutes = _estimateWalkingMinutes(distance);

    return timeInMinutes.toString();
  }

  int _estimateWalkingMinutes(double distanceMeters) {
    final minutes = ((distanceMeters / _walkingSpeedMps) / 60).round();
    if (distanceMeters > 0 && minutes == 0) {
      return 1;
    }
    return minutes;
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
    _selectedTouristPlace = null;
    _activeRoute = route;
    _routeDistanceMeters = 0;
    _routeDurationMinutes = 0;
    _isRouteFallback = false;
    notifyListeners();
  }

  void setTouristRoute(TouristPlace place, RouteResult routeResult) {
    _targetStop = null;
    _selectedTouristPlace = place;
    _activeRoute = routeResult.points;
    _routeDistanceMeters = routeResult.distanceMeters;
    _routeDurationMinutes = routeResult.durationMinutes;
    _isRouteFallback = routeResult.isFallback;
    notifyListeners();
  }

  void clearRoute() {
    _targetStop = null;
    _selectedTouristPlace = null;
    _activeRoute = [];
    _routeDistanceMeters = 0;
    _routeDurationMinutes = 0;
    _isRouteFallback = false;
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
