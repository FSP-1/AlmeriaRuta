import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodels/map_viewmodel.dart';
import '../models/filter_mode.dart';
import '../widgets/search_widget.dart';
import '../widgets/stop_info_sheet.dart';
import '../widgets/map_floating_buttons.dart';
import '../widgets/line_filter_sheet.dart';
import '../widgets/map_filter_bar.dart';
import '../widgets/map_overlay_banners.dart';
import 'map_fab_actions.dart';
import 'map_onboarding_flow.dart';
import '../tourism/viewmodels/tourism_viewmodel.dart';
import '../tourism/widgets/tourism_category_sheet.dart';
import '../tourism/widgets/tourist_place_sheet.dart';
import '../tourism/widgets/tourism_markers_layer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';

class OptimizedMapView extends StatefulWidget {
  final StopModel? initialStop;
  final String? initialLineId;
  final bool openWithFavoritesFilter;

  const OptimizedMapView({
    super.key,
    this.initialStop,
    this.initialLineId,
    this.openWithFavoritesFilter = false,
  });

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
      _initializeMapView();
    });
  }

  Future<void> _initializeMapView() async {
    final vm = context.read<MapViewModel>();
    await vm.initialize();

    if (!mounted) return;

    if (widget.initialStop != null) {
      if (widget.openWithFavoritesFilter) {
        _mapController.move(LatLng(widget.initialStop!.lat, widget.initialStop!.lon), 16.0);
      } else {
        await vm.showStopWithRouteFromExternal(widget.initialStop!);
        if (!mounted) return;
        _mapController.move(LatLng(widget.initialStop!.lat, widget.initialStop!.lon), 16.0);
      }
    }

    if (widget.openWithFavoritesFilter) {
      await vm.refreshFavoriteStops();
      vm.clearRoute();
      vm.setFilter(const MapFilter.favorites());
    }

    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    await maybeShowMapOnboarding(context);
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
            onPressed: () => showMapTutorialFlow(context: context, isFirstTime: false),
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
        ],
      ),
      body: Consumer2<MapViewModel, TourismViewModel>(
        builder: (context, mapViewModel, tourismViewModel, child) {
          final isFavoritesFilterEmpty =
              mapViewModel.currentFilter.mode == FilterMode.favorites &&
              !mapViewModel.isLoadingStops &&
              mapViewModel.filteredStops.isEmpty;

            final hasActiveZone = mapViewModel.activeZone != null;

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
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.almeriarutav02',
                        ),
                        // Zona activa resaltada
                        PolygonLayer(
                          polygons: hasActiveZone
                              ? <Polygon<Object>>[
                                  Polygon<Object>(
                                    points: mapViewModel.activeZone!.polygon,
                                    color: Colors.green.withValues(alpha: 0.08),
                                    borderColor: Colors.green.withValues(alpha: 0.7),
                                    borderStrokeWidth: 2,
                                  ),
                                ]
                              : <Polygon<Object>>[],
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
                        if (tourismViewModel.isEnabled)
                          TourismMarkersLayer(
                            places: tourismViewModel.filteredPlaces,
                            onPlaceTap: (place) {
                              showTouristPlaceSheet(
                                context: context,
                                place: place,
                                mapViewModel: mapViewModel,
                                onOpenDirections: () => openTouristDirections(
                                  context: context,
                                  mapViewModel: mapViewModel,
                                  place: place,
                                ),
                              );
                            },
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
                  child: const FavoritesEmptyBanner(),
                ),
              if (hasActiveZone)
                Positioned(
                  top: isFavoritesFilterEmpty ? 140 : 72,
                  left: 16,
                  right: 16,
                  child: ActiveZoneBanner(
                    zone: mapViewModel.activeZone!,
                    onClear: mapViewModel.clearZoneFilter,
                  ),
                ),
              if (tourismViewModel.isEnabled)
                Positioned(
                  top: hasActiveZone
                      ? (isFavoritesFilterEmpty ? 234 : 166)
                      : (isFavoritesFilterEmpty ? 140 : 72),
                  left: 16,
                  right: 16,
                  child: TourismModeBanner(
                    title: tourismViewModel.selectedCategory == null
                        ? 'Turismo: todos'
                        : 'Turismo: ${tourismCategoryLabel(tourismViewModel.selectedCategory!)}',
                    onTune: () => showTourismCategorySelector(
                      context: context,
                      tourismViewModel: tourismViewModel,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer2<MapViewModel, TourismViewModel>(
        builder: (context, mapViewModel, tourismViewModel, child) {
          return MapFloatingButtons(
            hasActiveRoute: mapViewModel.activeRoute.isNotEmpty,
            touristModeEnabled: tourismViewModel.isEnabled,
            onClearRoute: () => mapViewModel.clearRoute(),
            onMyLocation: () {
              MapFabActions.centerOnUser(
                mapController: _mapController,
                userLocation: mapViewModel.userLocation,
              );
            },
            onFavorites: () => MapFabActions.openFavorites(
              context: context,
              mapViewModel: mapViewModel,
              mapController: _mapController,
            ),
            onZones: () => MapFabActions.openZones(
                context: context,
                mapViewModel: mapViewModel,
                mapController: _mapController,
              ),
            onTouristMode: () => MapFabActions.toggleTouristMode(
              context: context,
              tourismViewModel: tourismViewModel,
            ),
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

}
