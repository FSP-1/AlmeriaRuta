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
import '../tourism/viewmodels/tourism_viewmodel.dart';
import '../tourism/models/tourist_place.dart';
import '../tourism/widgets/tourism_markers_layer.dart';
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

  void _showZoneSelector(MapViewModel mapViewModel) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Filtrar por zona',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.layers_clear, color: Colors.grey),
              title: const Text('Todas las zonas'),
              onTap: () {
                mapViewModel.clearZoneFilter();
                Navigator.pop(context);
              },
            ),
            ...AlmeriaZones.transportZones.map((zone) => ListTile(
                  leading: const Icon(Icons.map, color: Colors.green),
                  title: Text(zone.name),
                  subtitle: Text(zone.description),
                  onTap: () {
                    mapViewModel.setActiveZone(zone);
                    _mapController.move(zone.center, 13.0);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showTourismCategorySelector(TourismViewModel tourismViewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(
                  title: Text(
                    'Filtro turístico',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.apps, color: Colors.blue),
                  title: const Text('Todos'),
                  trailing: tourismViewModel.selectedCategory == null
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    tourismViewModel.setCategory(null);
                    Navigator.pop(context);
                  },
                ),
                ...TouristCategory.values.map(
                  (category) => ListTile(
                    leading: const Icon(Icons.place, color: Colors.blue),
                    title: Text(_tourismCategoryLabel(category)),
                    trailing: tourismViewModel.selectedCategory == category
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      tourismViewModel.setCategory(category);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
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
                              _showTouristPlaceInfo(context, place, mapViewModel);
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
              if (hasActiveZone)
                Positioned(
                  top: isFavoritesFilterEmpty ? 140 : 72,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.map, color: Colors.green),
                      title: Text('Zona activa: ${mapViewModel.activeZone!.name}'),
                      subtitle: Text(mapViewModel.activeZone!.description),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => mapViewModel.clearZoneFilter(),
                      ),
                    ),
                  ),
                ),
              if (tourismViewModel.isEnabled)
                Positioned(
                  top: hasActiveZone
                      ? (isFavoritesFilterEmpty ? 234 : 166)
                      : (isFavoritesFilterEmpty ? 140 : 72),
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.tour, color: Colors.blue),
                      title: Text(
                        tourismViewModel.selectedCategory == null
                            ? 'Turismo: todos'
                            : 'Turismo: ${_tourismCategoryLabel(tourismViewModel.selectedCategory!)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.tune, color: Colors.blue),
                        onPressed: () => _showTourismCategorySelector(tourismViewModel),
                      ),
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
            onZones: () {
              _showZoneSelector(mapViewModel);
            },
            onTouristMode: () {
              tourismViewModel.toggleEnabled();
              final text = tourismViewModel.isEnabled
                  ? 'Modo turístico activado'
                  : 'Modo turístico desactivado';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(text), duration: const Duration(seconds: 1)),
              );
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

  void _showTouristPlaceInfo(
    BuildContext parentContext,
    TouristPlace place,
    MapViewModel mapViewModel,
  ) {
    final hasRouteToThisPlace =
        mapViewModel.activeRoute.isNotEmpty &&
        mapViewModel.selectedTouristPlace?.id == place.id;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.place, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(place.description),
              const SizedBox(height: 12),
              Text(
                'Distancia estimada: ${mapViewModel.calculateDistanceToPoint(place.location)} m',
              ),
              Text(
                'Tiempo estimado: ${mapViewModel.calculateWalkingTimeToPoint(place.location)} min',
              ),
              if (hasRouteToThisPlace) ...[
                const SizedBox(height: 10),
                Text(
                  'Ruta activa: ${mapViewModel.routeDistanceMeters.round()} m • ${mapViewModel.routeDurationMinutes} min',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (mapViewModel.isRouteFallback)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Ruta aproximada en linea recta (fallback)',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openTouristDirections(mapViewModel, place);
                      },
                      icon: const Icon(Icons.directions_walk),
                      label: Text(hasRouteToThisPlace ? 'Recalcular' : 'Como llegar'),
                    ),
                  ),
                  if (hasRouteToThisPlace) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        mapViewModel.clearRoute();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTouristDirections(MapViewModel mapViewModel, TouristPlace place) async {
    if (mapViewModel.userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener tu ubicacion actual')),
      );
      return;
    }

    final result = await mapViewModel.getRouteResult(
      mapViewModel.userLocation!,
      place.location,
    );

    if (!mounted) return;

    mapViewModel.setTouristRoute(place, result);

    final fallbackText = result.isFallback ? ' (fallback)' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ruta a ${place.name}: ${result.distanceMeters.round()} m · ${result.durationMinutes} min$fallbackText',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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

  String _tourismCategoryLabel(TouristCategory category) {
    switch (category) {
      case TouristCategory.monument:
        return 'Monumentos';
      case TouristCategory.beach:
        return 'Playas';
      case TouristCategory.museum:
        return 'Museos';
      case TouristCategory.park:
        return 'Parques';
      case TouristCategory.shopping:
        return 'Compras';
      case TouristCategory.port:
        return 'Puerto';
      case TouristCategory.leisure:
        return 'Ocio';
    }
  }

}
