import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodels/map_viewmodel.dart';
import '../models/zone_model.dart';
import '../models/filter_mode.dart';
import '../widgets/search_widget.dart';
import '../widgets/favorites_sheet.dart';
import '../widgets/map_tutorial_dialog.dart';
import '../widgets/favorite_line_selector.dart';
import '../widgets/stop_info_sheet.dart';
import '../widgets/map_floating_buttons.dart';
import '../widgets/line_filter_sheet.dart';
import '../widgets/map_filter_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/onboarding_service.dart';

class OptimizedMapView extends StatefulWidget {
  const OptimizedMapView({super.key});

  @override
  State<OptimizedMapView> createState() => _OptimizedMapViewState();
}

class _OptimizedMapViewState extends State<OptimizedMapView> {
  final MapController _mapController = MapController();
  double _currentZoom = 13.0;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<MapViewModel>();
      vm.initialize();
      _checkOnboarding();
    });
  }

  Future<void> _checkOnboarding() async {
    final done = await OnboardingService.isDone();
    if (!done && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMapTutorial(isFirstTime: true);
      });
    }
  }

  void _showLineFilterSelector(MapViewModel mapViewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LineFilterSheet(mapViewModel: mapViewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          final isFavoritesFilterEmpty =
              mapViewModel.currentFilter.mode == FilterMode.favorites &&
              !mapViewModel.isLoadingStops &&
              mapViewModel.filteredStops.isEmpty;

          return Stack(
            children: [
              Column(
                children: [
                  MapFilterBar(
                    mapViewModel: mapViewModel,
                    onOpenLineSelector: () => _showLineFilterSelector(mapViewModel),
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
                        if (_currentZoom >= 12 && !mapViewModel.isLoadingStops)
                          MarkerLayer(
                            markers: [
                              // Paradas filtradas
                              ...(mapViewModel.activeRoute.isNotEmpty && mapViewModel.targetStop != null
                                  ? [mapViewModel.targetStop!]
                                  : mapViewModel.filteredStops).map((stop) => Marker(
                                point: LatLng(stop.lat, stop.lon),
                                width: 30,
                                height: 30,
                                child: GestureDetector(
                                  onTap: () => _showStopInfo(context, stop, mapViewModel),
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
                              if (mapViewModel.userLocation != null)
                                Marker(
                                  point: mapViewModel.userLocation!,
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
              if (isFavoritesFilterEmpty)
                Positioned(
                  top: 72,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.star_border, color: AppTheme.primaryRed),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No tienes paradas favoritas. Añade una desde el detalle de parada.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
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
              if (mapViewModel.userLocation != null) {
                _mapController.move(mapViewModel.userLocation!, 15.0);
              } else {
                _mapController.move(const LatLng(36.8381, -2.4597), 13.0);
              }
            },
            onFavorites: () {
              mapViewModel.refreshFavoriteStops();
              showModalBottomSheet(
                context: context,
                builder: (_) => FavoritesSheet(
                  mapController: _mapController,
                  allStops: mapViewModel.stops,
                  onLineSelected: (lineId) {
                    mapViewModel.setFilter(MapFilter.line(lineId));
                  },
                  onStopSelected: (stop) {
                    mapViewModel.clearRoute();
                    mapViewModel.refreshFavoriteStops();
                    mapViewModel.setFilter(const MapFilter.favorites());
                  },
                  onFavoritesChanged: () {
                    mapViewModel.refreshFavoriteStops();
                  },
                ),
              ).whenComplete(() {
                mapViewModel.refreshFavoriteStops();
              });
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showStopInfo(BuildContext parentContext, StopModel stop, MapViewModel mapViewModel) {
    showModalBottomSheet(
      context: parentContext,
      builder: (context) => StopInfoSheet(
        stop: stop,
        userLocation: mapViewModel.userLocation,
        onFavoritesChanged: () {
          mapViewModel.refreshFavoriteStops();
        },
        onGetDirections: () {
          _openDirections(mapViewModel, stop);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openDirections(MapViewModel mapViewModel, StopModel stop) async {
    if (mapViewModel.userLocation == null) return;
    
    try {
      final route = await mapViewModel.getRoute(
        mapViewModel.userLocation!, 
        LatLng(stop.lat, stop.lon)
      );
      mapViewModel.setRoute(stop, route);
    } catch (e) {
      // Si falla el routing, usar línea recta como fallback
      final route = [mapViewModel.userLocation!, LatLng(stop.lat, stop.lon)];
      mapViewModel.setRoute(stop, route);
    }
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
              final vm = context.read<MapViewModel>();
              if (vm.lines.isNotEmpty) _showFavoriteLineSelector();
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
      builder: (_) {
        final vm = context.read<MapViewModel>();
        return FavoriteLineSelector(
          lines: vm.lines,
          onLineSelected: (lineId) {
            vm.setFilter(MapFilter.line(lineId));
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
