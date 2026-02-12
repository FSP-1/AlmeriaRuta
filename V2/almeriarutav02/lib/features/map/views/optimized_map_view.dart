import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../viewmodels/map_viewmodel.dart';
import '../viewmodels/favorites_viewmodel.dart';
import '../models/favorite_model.dart';
import '../models/zone_model.dart';
import '../widgets/search_widget.dart';
import '../widgets/favorites_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/bus_api_service.dart';

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
  String? _selectedLineId;
  bool _isLoadingStops = false;
  LatLng? _userLocation;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadStops();
    _getCurrentLocation();
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
      });
    } catch (e) {
      setState(() => _isLoadingStops = false);
    }
  }

  List<StopModel> get _filteredStops {
    return _stops.where((stop) {
      final matchesLine = _selectedLineId == null || stop.lineIds.contains(_selectedLineId);
      return matchesLine;
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
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedLineId,
                              hint: const Text('Líneas'),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Todas')),
                                ..._lines.map((line) => DropdownMenuItem(
                                      value: line.id,
                                      child: Text(line.name),
                                    )),
                              ],
                              onChanged: (value) => setState(() => _selectedLineId = value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<ZoneModel?>(
                              value: null,
                              hint: const Text('Zonas'),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Todas')),
                                ...AlmeriaZones.zones.map((zone) => DropdownMenuItem(
                                  value: zone,
                                  child: Text(zone.name),
                                )),
                              ],
                              onChanged: (zone) {
                                if (zone != null) {
                                  _mapController.move(zone.center, 15.0);
                                }
                              },
                            ),
                          ),
                        ],
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
                // Botón favoritos
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: "favorites",
                    mini: true,
                    backgroundColor: Colors.amber,
                    child: const Icon(Icons.star, color: Colors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => FavoritesSheet(
                          mapController: _mapController,
                          allStops: _stops,
                          onLineSelected: (lineId) {
                            setState(() => _selectedLineId = lineId);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<MapViewModel>(
          builder: (context, mapViewModel, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mapViewModel.activeRoute.isNotEmpty)
                  FloatingActionButton(
                    heroTag: "clear_route",
                    onPressed: () => mapViewModel.clearRoute(),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                if (mapViewModel.activeRoute.isNotEmpty)
                  const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "my_location",
                  onPressed: () {
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 15.0);
                    } else {
                      _mapController.move(const LatLng(36.8381, -2.4597), 13.0);
                    }
                  },
                  backgroundColor: AppTheme.primaryRed,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showStopInfo(BuildContext parentContext, StopModel stop) {
    final mapViewModel = parentContext.read<MapViewModel>();
    
    showModalBottomSheet(
      context: parentContext,
      builder: (context) => ChangeNotifierProvider(
        create: (_) => FavoritesViewModel()..load(),
        child: Consumer<FavoritesViewModel>(
          builder: (context, favVM, _) {
            final isFav = favVM.isFavorite(stop.id, FavoriteType.stop);
            
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.primaryRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stop.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                        onPressed: () {
                          if (isFav) {
                            favVM.remove(stop.id, FavoriteType.stop);
                          } else {
                            favVM.add(
                              FavoriteModel(
                                id: stop.id,
                                name: stop.name,
                                type: FavoriteType.stop,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Líneas: ${stop.lineIds.join(", ")}'),
                  if (_userLocation != null) ...[
                    const SizedBox(height: 8),
                    Text('Distancia: ${_calculateDistance(stop)} m'),
                    Text('Tiempo caminando: ${_calculateWalkingTime(stop)} min'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        _openDirections(mapViewModel, stop);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Cómo llegar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
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

  String _calculateWalkingTime(StopModel stop) {
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

  String _calculateDistance(StopModel stop) {
    if (_userLocation == null) return '---';
    
    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      stop.lat,
      stop.lon,
    );
    
    return distance.round().toString();
  }
}