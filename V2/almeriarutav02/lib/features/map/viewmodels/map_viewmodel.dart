import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import '../models/location_model.dart';
import '../models/zone_model.dart';
import '../models/filter_mode.dart';
import '../models/favorite_model.dart';
import '../services/osrm_routing_service.dart';
import '../services/stop_loader_service.dart';
import '../services/bus_route_polyline_builder.dart';
import '../tourism/models/tourist_place.dart';
import '../tourism/utils/tourist_bus_route_planner.dart';
import '../../../shared/services/line_models.dart';

export '../services/osrm_routing_service.dart' show RouteResult;

class MapViewModel extends ChangeNotifier {
  final OsrmRoutingService _routing;
  final StopLoaderService _stopLoader;
  final BusRoutePolylineBuilder _polylineBuilder;

  MapViewModel({
    OsrmRoutingService? routing,
    StopLoaderService? stopLoader,
    BusRoutePolylineBuilder? polylineBuilder,
  })  : _routing = routing ?? OsrmRoutingService(),
        _stopLoader = stopLoader ?? StopLoaderService(),
        _polylineBuilder = polylineBuilder ?? BusRoutePolylineBuilder();

  // ── State ─────────────────────────────────────────────────────────────────

  List<StopModel> _stops = [];
  List<LineModel> _lines = [];
  LatLng? _userLocation;
  Timer? _routeLocationRefreshTimer;
  bool _showBusStops = true;
  MapFilter _currentFilter = const MapFilter.nearby();
  Set<String> _favoriteStopIds = {};
  ZoneModel? _activeZone;
  bool _isLoadingStops = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  // Route state
  StopModel? _targetStop;
  TouristPlace? _selectedTouristPlace;
  List<StopModel> _touristBusRouteStops = [];
  TouristBusRoutePlan? _activeTouristBusRoutePlan;
  bool _isTouristBusRouteOnlyMode = false;
  List<LatLng> _activeRoute = [];
  List<LatLng> _touristWalkToBoardRoute = [];
  List<LatLng> _touristBusRoute = [];
  List<LatLng> _touristWalkToPlaceRoute = [];
  double _routeDistanceMeters = 0;
  int _routeDurationMinutes = 0;
  bool _isRouteFallback = false;

  // Legacy zone state
  LocationModel? _selectedLocation;
  ZoneModel? _selectedZone;
  List<StopModel> _stopsInZone = [];
  Map<String, int> _linesInZone = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  List<StopModel> get stops => _stops;
  List<StopModel> get filteredStops => _filteredStops();
  List<LineModel> get lines => _lines;
  LatLng? get userLocation => _userLocation;
  bool get showBusStops => _showBusStops;
  MapFilter get currentFilter => _currentFilter;
  bool get isLoadingStops => _isLoadingStops;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<String> get favoriteStopIds => _favoriteStopIds;
  ZoneModel? get activeZone => _activeZone;

  StopModel? get targetStop => _targetStop;
  TouristPlace? get selectedTouristPlace => _selectedTouristPlace;
  List<StopModel> get touristBusRouteStops => _touristBusRouteStops;
  TouristBusRoutePlan? get activeTouristBusRoutePlan => _activeTouristBusRoutePlan;
  bool get isTouristBusRouteOnlyMode => _isTouristBusRouteOnlyMode;
  List<LatLng> get activeRoute => _activeRoute;
  List<LatLng> get touristWalkToBoardRoute => _touristWalkToBoardRoute;
  List<LatLng> get touristBusRoute => _touristBusRoute;
  List<LatLng> get touristWalkToPlaceRoute => _touristWalkToPlaceRoute;
  double get routeDistanceMeters => _routeDistanceMeters;
  int get routeDurationMinutes => _routeDurationMinutes;
  bool get isRouteFallback => _isRouteFallback;

  LocationModel? get selectedLocation => _selectedLocation;
  ZoneModel? get selectedZone => _selectedZone;
  List<StopModel> get stopsInZone => _stopsInZone;
  Map<String, int> get linesInZone => _linesInZone;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    await getCurrentLocation();
    await loadStops();
    await refreshFavoriteStops();
    _initialized = true;
  }

  // ── Stops ─────────────────────────────────────────────────────────────────

  Future<void> loadStops() async {
    if (_isLoadingStops || _stops.isNotEmpty) return;
    _isLoadingStops = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _stopLoader.load();
      _lines = result.lines;
      _stops = result.stops;
    } catch (e) {
      _errorMessage = 'Error al cargar paradas: $e';
    } finally {
      _isLoadingStops = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> getCurrentLocation() async {
    if (_userLocation != null) return;
    await refreshCurrentLocation();
  }

  Future<void> refreshCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // No podemos obtener ubicación; mantener la que haya o fallback.
        _userLocation ??= const LatLng(36.8381, -2.4597);
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _userLocation = LatLng(position.latitude, position.longitude);
    } catch (_) {
      _userLocation ??= const LatLng(36.8381, -2.4597);
    }
    notifyListeners();
  }

  void _startRouteLocationRefreshTimer() {
    _routeLocationRefreshTimer?.cancel();
    // Refresco inmediato y luego cada 3 minutos.
    unawaited(refreshCurrentLocation());
    _routeLocationRefreshTimer = Timer.periodic(
      const Duration(minutes: 3),
      (_) => unawaited(refreshCurrentLocation()),
    );
  }

  void _stopRouteLocationRefreshTimer() {
    _routeLocationRefreshTimer?.cancel();
    _routeLocationRefreshTimer = null;
  }

  // ── Favorites ─────────────────────────────────────────────────────────────

  Future<void> refreshFavoriteStops() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('favorites') ?? [];
    final ids = <String>{};
    for (final item in data) {
      try {
        final fav = FavoriteModel.fromJson(json.decode(item));
        if (fav.type == FavoriteType.stop) ids.add(fav.id);
      } catch (_) {}
    }
    _favoriteStopIds = ids;
    if (_currentFilter.mode == FilterMode.favorites && _favoriteStopIds.isEmpty) {
      _currentFilter = const MapFilter.nearby();
    }
    notifyListeners();
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  void setFilter(MapFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setShowBusStops(bool value) {
    if (_showBusStops == value) return;
    _showBusStops = value;
    notifyListeners();
  }

  List<StopModel> _filteredStops() {
    if (!_showBusStops) return <StopModel>[];

    final byMode = switch (_currentFilter.mode) {
      FilterMode.nearby => _userLocation == null
          ? <StopModel>[]
          : _stops.where((s) {
              return Geolocator.distanceBetween(
                    _userLocation!.latitude, _userLocation!.longitude,
                    s.lat, s.lon,
                  ) <=
                  800;
            }).toList(),
      FilterMode.all => _stops,
      FilterMode.favorites => _favoriteStopIds.isEmpty
          ? <StopModel>[]
          : _stops.where((s) => _favoriteStopIds.contains(s.id)).toList(),
      FilterMode.line => _currentFilter.lineId == null
          ? _stops
          : _stops.where((s) => s.lineIds.contains(_currentFilter.lineId)).toList(),
    };

    if (_activeZone == null) return byMode;
    return byMode.where((s) {
      return AlmeriaZones.isPointInsidePolygon(LatLng(s.lat, s.lon), _activeZone!.polygon);
    }).toList();
  }

  // ── Zone ──────────────────────────────────────────────────────────────────

  void setActiveZone(ZoneModel? zone) {
    _activeZone = zone;
    notifyListeners();
  }

  void clearZoneFilter() {
    _activeZone = null;
    notifyListeners();
  }

  // ── Routing ───────────────────────────────────────────────────────────────

  Future<List<LatLng>> getRoute(LatLng from, LatLng to, {String profile = 'walking'}) async {
    final result = await getRouteResult(from, to, profile: profile);
    return result.points;
  }

  Future<RouteResult> getRouteResult(LatLng from, LatLng to, {String profile = 'walking'}) =>
      _routing.getRoute(from, to, profile: profile);

  void setRoute(StopModel stop, List<LatLng> route) {
    _targetStop = stop;
    _selectedTouristPlace = null;
    _touristBusRouteStops = [];
    _activeTouristBusRoutePlan = null;
    _isTouristBusRouteOnlyMode = false;
    _activeRoute = route;
    _touristWalkToBoardRoute = [];
    _touristBusRoute = [];
    _touristWalkToPlaceRoute = [];
    _routeDistanceMeters = 0;
    _routeDurationMinutes = 0;
    _isRouteFallback = false;
    _startRouteLocationRefreshTimer();
    notifyListeners();
  }

  void setTouristRoute(TouristPlace place, RouteResult result) {
    _targetStop = null;
    _selectedTouristPlace = place;
    _touristBusRouteStops = [];
    _activeTouristBusRoutePlan = null;
    _isTouristBusRouteOnlyMode = false;
    _activeRoute = result.points;
    _touristWalkToBoardRoute = [];
    _touristBusRoute = [];
    _touristWalkToPlaceRoute = [];
    _routeDistanceMeters = result.distanceMeters;
    _routeDurationMinutes = result.durationMinutes;
    _isRouteFallback = result.isFallback;
    _startRouteLocationRefreshTimer();
    notifyListeners();
  }

  void clearRoute() {
    _targetStop = null;
    _selectedTouristPlace = null;
    _touristBusRouteStops = [];
    _activeTouristBusRoutePlan = null;
    _isTouristBusRouteOnlyMode = false;
    _activeRoute = [];
    _touristWalkToBoardRoute = [];
    _touristBusRoute = [];
    _touristWalkToPlaceRoute = [];
    _routeDistanceMeters = 0;
    _routeDurationMinutes = 0;
    _isRouteFallback = false;
    _stopRouteLocationRefreshTimer();
    notifyListeners();
  }

  // ── Tourist bus route ─────────────────────────────────────────────────────

  List<TouristNearbyStopOption> getNearbyTouristStops(
    TouristPlace place, {
    double maxDistanceMeters = 650,
    double maxWalkToBoardMeters = double.infinity,
    int limit = 8,
  }) {
    final raw = TouristBusRoutePlanner.findNearbyStops(
      place: place,
      allStops: _stops,
      allLines: _lines,
      userLocation: _userLocation,
      maxDistanceMeters: maxDistanceMeters,
      maxWalkToBoardMeters: maxWalkToBoardMeters,
      limit: limit * 3, // fetch extra so dedupe + top selection works
    );

    // Deduplicate by stop.id: keep the option with smallest distanceToPlaceMeters
    final Map<String, TouristNearbyStopOption> bestByStop = {};
    for (final opt in raw) {
      final id = opt.stop.id;
      final existing = bestByStop[id];
      if (existing == null || opt.distanceToPlaceMeters < existing.distanceToPlaceMeters) {
        bestByStop[id] = opt;
      }
    }

    final deduped = bestByStop.values.toList()
      ..sort((a, b) => a.distanceToPlaceMeters.compareTo(b.distanceToPlaceMeters));

    return deduped.take(limit).toList();
  }

  TouristBusRoutePlan? buildTouristBusRoutePlan(TouristPlace place, StopModel destinationStop) {
    if (_userLocation == null) return null;

    final plan = TouristBusRoutePlanner.buildPlan(
      place: place,
      userLocation: _userLocation!,
      destinationStop: destinationStop,
      allLines: _lines,
    );
    if (plan == null) return null;

  /*  final directWalkMeters = Geolocator.distanceBetween(
      _userLocation!.latitude, _userLocation!.longitude,
      place.location.latitude, place.location.longitude,
    );*/
    return plan ;
  }

  Future<void> applyTouristBusRoutePlan(TouristBusRoutePlan plan) async {
    if (_userLocation == null) return;
    _isLoading = true;
    notifyListeners();

    final parts = await _polylineBuilder.buildParts(plan, _userLocation!);
    final polyline = parts.combined.isEmpty ? plan.routePoints : parts.combined;

    _targetStop = null;
    _selectedTouristPlace = plan.place;
    _touristBusRouteStops = plan.routeStops;
    _activeTouristBusRoutePlan = plan;
    _isTouristBusRouteOnlyMode = true;
    _activeRoute = polyline;
    _touristWalkToBoardRoute = parts.walkToBoard;
    _touristBusRoute = parts.busRoute;
    _touristWalkToPlaceRoute = parts.walkToPlace;
    _routeDistanceMeters = plan.totalDistanceMeters;
    _routeDurationMinutes = plan.totalDurationMinutes;
    _isRouteFallback = false;
    _isLoading = false;
    _startRouteLocationRefreshTimer();

    debugPrint('[MapViewModel] Applying tourist plan: place=${plan.place.name} '
      'segments=${plan.segments.length} routeStops=${plan.routeStops.length} '
      'polylinePoints=${_activeRoute.length} busPoints=${_touristBusRoute.length} '
      'walkToBoardPoints=${_touristWalkToBoardRoute.length} walkToPlacePoints=${_touristWalkToPlaceRoute.length}');

    notifyListeners();
  }

  @override
  void dispose() {
    _stopRouteLocationRefreshTimer();
    super.dispose();
  }

  // ── Distance helpers ──────────────────────────────────────────────────────

  String calculateDistance(StopModel stop) {
    if (_userLocation == null) return '---';
    return Geolocator.distanceBetween(
      _userLocation!.latitude, _userLocation!.longitude, stop.lat, stop.lon,
    ).round().toString();
  }

  String calculateWalkingTime(StopModel stop) {
    if (_userLocation == null) return '---';
    final d = Geolocator.distanceBetween(
      _userLocation!.latitude, _userLocation!.longitude, stop.lat, stop.lon,
    );
    return OsrmRoutingService.walkMinutes(d).toString();
  }

  String calculateDistanceToPoint(LatLng point) {
    if (_userLocation == null) return '---';
    return Geolocator.distanceBetween(
      _userLocation!.latitude, _userLocation!.longitude,
      point.latitude, point.longitude,
    ).round().toString();
  }

  String calculateWalkingTimeToPoint(LatLng point) {
    if (_userLocation == null) return '---';
    final d = Geolocator.distanceBetween(
      _userLocation!.latitude, _userLocation!.longitude,
      point.latitude, point.longitude,
    );
    return OsrmRoutingService.walkMinutes(d).toString();
  }

  // ── Legacy ────────────────────────────────────────────────────────────────

  void focusStopFromExternal(
    StopModel stop, {
    String? lineId,
    bool setFilter = true,
  }) {
    _targetStop = stop;
    _selectedTouristPlace = null;
    _activeRoute = [];
    _routeDistanceMeters = 0;
    _routeDurationMinutes = 0;
    _isRouteFallback = false;
    if (setFilter) {
      _currentFilter = lineId == null ? const MapFilter.all() : MapFilter.line(lineId);
    }
    notifyListeners();
  }

  Future<void> showStopWithRouteFromExternal(StopModel stop) async {
    final from = _userLocation ?? const LatLng(36.8381, -2.4597);
    final route = await getRoute(from, LatLng(stop.lat, stop.lon));
    setRoute(stop, route);
  }

  void setSelectedLocation(LocationModel location) {
    _selectedLocation = location;
    _errorMessage = null;
    notifyListeners();
  }

  void setSelectedZone(ZoneModel? zone) {
    _selectedZone = zone;
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

  void updateStopsForZone(List<StopModel> allStops) {
    if (_selectedZone == null) {
      _stopsInZone = [];
      _linesInZone = {};
      notifyListeners();
      return;
    }
    _stopsInZone = allStops.where((stop) {
      return AlmeriaZones.isPointInsidePolygon(
        LatLng(stop.lat, stop.lon),
        _selectedZone!.polygon,
      );
    }).toList();

    // Calcular líneas sin inflar por paradas repetidas en la misma ruta.
    final counts = <String, int>{};
    final seenStopIds = <String>{};

    for (final stop in _stopsInZone) {
      if (!seenStopIds.add(stop.id)) continue;
      for (final lineId in stop.lineIds) {
        counts[lineId] = (counts[lineId] ?? 0) + 1;
      }
    }

    _linesInZone = Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    notifyListeners();
  }
}
