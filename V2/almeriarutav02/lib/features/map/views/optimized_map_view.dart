import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../viewmodels/map_viewmodel.dart';
import '../models/zone_model.dart';
import '../models/filter_mode.dart';
import '../widgets/search_widget.dart';
import '../widgets/favorites_sheet.dart';
import '../widgets/map_tutorial_dialog.dart';
import '../widgets/favorite_line_selector.dart';
import '../widgets/stop_info_sheet.dart';
import '../widgets/map_floating_buttons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/bus_api_service.dart';
import '../../../shared/services/onboarding_service.dart';

class OptimizedMapView extends StatefulWidget {
  const OptimizedMapView({super.key});

  @override
  State<OptimizedMapView> createState() => _OptimizedMapViewState();
}

class _OptimizedMapViewState extends State<OptimizedMapView> {
  final MapController _mapController = MapController();
  double _currentZoom = 13.0;
  List<StopModel> _stops = [];
  List<LineModel> _lines = [];
  MapFilter _currentFilter = const MapFilter.nearby();
  bool _isLoadingStops = false;
  LatLng? _userLocation;
  bool _showSearch = false;
  static const double _nearbyRadius = 800; // metros

  @override
  void initState() {
    super.initState();
    _loadStops();
    _getCurrentLocation();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final done = await OnboardingService.isDone();
    if (!done && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMapTutorial(isFirstTime: true);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        
        print('GPS Location: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadStops() async {
    setState(() => _isLoadingStops = true);
    try {
      final apiService = BusApiService();
      final lines = await apiService.getLines();
      final uniqueStops = <String, StopModel>{};
      
      for (final line in lines) {
        final stops = await apiService.getLineStops(line.id);
        
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
      
      setState(() {
        _lines = lines;
        _stops = uniqueStops.values.toList();
        _isLoadingStops = false;
        // Asegurar que inicia con paradas cercanas si hay ubicación
        if (_userLocation != null) {
          _currentFilter = const MapFilter.nearby();
        }
      });
    } catch (e) {
      setState(() => _isLoadingStops = false);
    }
  }

  List<StopModel> get _filteredStops {
    return _stops.where((stop) {
      switch (_currentFilter.mode) {
        case FilterMode.nearby:
          // Solo paradas cercanas
          if (_userLocation == null) return true; // Si no hay ubicación, mostrar todas
          final distance = Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            stop.lat,
            stop.lon,
          );
          return distance <= _nearbyRadius;
        
        case FilterMode.all:
          // Todas las paradas
          return true;
        
        case FilterMode.line:
          // Solo paradas de la línea seleccionada
          return _currentFilter.lineId != null && 
                 stop.lineIds.contains(_currentFilter.lineId);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mapa de Almería'),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showMapTutorial(isFirstTime: false),
            ),
            IconButton(
              icon: Icon(_showSearch ? Icons.close : Icons.search),
              onPressed: () => setState(() => _showSearch = !_showSearch),
            ),
          ],
        ),
        body: Consumer<MapViewModel>(
          builder: (context, mapViewModel, child) {
            return Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[100],
                      child: DropdownButton<String>(
                        value: _currentFilter.mode == FilterMode.line 
                            ? _currentFilter.lineId 
                            : _currentFilter.mode.name,
                        hint: const Text('Filtro'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: 'nearby',
                            child: Row(
                              children: [
                                Icon(Icons.near_me, size: 16, color: AppTheme.primaryRed),
                                SizedBox(width: 8),
                                Text('Cercanas'),
                              ],
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'all',
                            child: Row(
                              children: [
                                Icon(Icons.list, size: 16, color: AppTheme.primaryRed),
                                SizedBox(width: 8),
                                Text('Todas'),
                              ],
                            ),
                          ),
                          ..._lines.map((line) => DropdownMenuItem(
                                value: line.id,
                                child: Row(
                                  children: [
                                    Icon(Icons.directions_bus, size: 16, color: AppTheme.primaryRed),
                                    SizedBox(width: 8),
                                    Text('Línea ${line.name}'),
                                  ],
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            if (value == 'nearby') {
                              _currentFilter = const MapFilter.nearby();
                            } else if (value == 'all') {
                              _currentFilter = const MapFilter.all();
                            } else if (value != null) {
                              _currentFilter = MapFilter.line(value);
                            }
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(36.8381, -2.4597),
                          initialZoom: 13.0,
                          minZoom: 10.0,
                          maxZoom: 18.0,
                          onPositionChanged: (position, hasGesture) {
                            setState(() {
                              _currentZoom = position.zoom;
                            });
                          },
                          onTap: (tapPosition, latLng) {
                            final zone = AlmeriaZones.findZoneByLatLng(latLng);
                            if (zone != null) {
                              _mapController.move(zone.center, 15.0);
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.almeriarutav02',
                          ),
                          // Polígonos de zonas (invisibles)
                          PolygonLayer(
                            polygons: AlmeriaZones.zones.map((zone) => Polygon(
                              points: zone.polygon,
                              color: Colors.transparent,
                              borderColor: Colors.transparent,
                              borderStrokeWidth: 0,
                            )).toList(),
                          ),
                          // Ruta activa
                          if (mapViewModel.activeRoute.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: mapViewModel.activeRoute,
                                  strokeWidth: 4,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          // Marcadores de paradas
                          if (_currentZoom >= 12 && !_isLoadingStops)
                            MarkerLayer(
                              markers: [
                                // Paradas filtradas
                                ...(mapViewModel.activeRoute.isNotEmpty && mapViewModel.targetStop != null
                                    ? [mapViewModel.targetStop!]
                                    : _filteredStops).map((stop) => Marker(
                                  point: LatLng(stop.lat, stop.lon),
                                  width: 30,
                                  height: 30,
                                  child: GestureDetector(
                                    onTap: () => _showStopInfo(context, stop),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: stop.lineIds.length > 1
                                            ? Colors.purple
                                            : AppTheme.primaryRed,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.directions_bus,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                )),
                                // Usuario
                                if (_userLocation != null)
                                  Marker(
                                    point: _userLocation!,
                                    width: 40,
                                    height: 40,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                '© OpenStreetMap contributors',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Widget de búsqueda
                if (_showSearch)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SearchWidget(
                      onLocationSelected: (location) {
                        _mapController.move(
                          LatLng(location.latitude, location.longitude),
                          15.0,
                        );
                        setState(() => _showSearch = false);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<MapViewModel>(
          builder: (context, mapViewModel, child) {
            return MapFloatingButtons(
              hasActiveRoute: mapViewModel.activeRoute.isNotEmpty,
              onClearRoute: () => mapViewModel.clearRoute(),
              onMyLocation: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 15.0);
                } else {
                  _mapController.move(const LatLng(36.8381, -2.4597), 13.0);
                }
              },
              onFavorites: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => FavoritesSheet(
                    mapController: _mapController,
                    allStops: _stops,
                    onLineSelected: (lineId) {
                      setState(() => _currentFilter = MapFilter.line(lineId));
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  void _showStopInfo(BuildContext parentContext, StopModel stop) {
    final mapViewModel = parentContext.read<MapViewModel>();
    
    showModalBottomSheet(
      context: parentContext,
      builder: (context) => StopInfoSheet(
        stop: stop,
        userLocation: _userLocation,
        onGetDirections: () {
          _openDirections(mapViewModel, stop);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openDirections(MapViewModel mapViewModel, StopModel stop) async {
    if (_userLocation == null) return;
    
    try {
      final route = await _getRoute(_userLocation!, LatLng(stop.lat, stop.lon));
      mapViewModel.setRoute(stop, route);
    } catch (e) {
      // Si falla el routing, usar línea recta como fallback
      final route = [_userLocation!, LatLng(stop.lat, stop.lon)];
      mapViewModel.setRoute(stop, route);
    }
  }

  Future<List<LatLng>> _getRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/walking/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson'
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Error getting route');
    }

    final data = json.decode(response.body);
    final coords = data['routes'][0]['geometry']['coordinates'] as List;

    return coords.map((c) => LatLng(c[1], c[0])).toList();
  }

  void _showMapTutorial({required bool isFirstTime}) {
    showDialog(
      context: context,
      barrierDismissible: !isFirstTime,
      builder: (_) => MapTutorialDialog(
        isFirstTime: isFirstTime,
        onComplete: () async {
          if (isFirstTime) {
            await OnboardingService.setDone();
            if (mounted) {
              Navigator.pop(context);
              if (_lines.isNotEmpty) _showFavoriteLineSelector();
            }
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showFavoriteLineSelector() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (_) => FavoriteLineSelector(
        lines: _lines,
        onLineSelected: (lineId) {
          setState(() => _currentFilter = MapFilter.line(lineId));
          Navigator.pop(context);
        },
      ),
    );
  }
}