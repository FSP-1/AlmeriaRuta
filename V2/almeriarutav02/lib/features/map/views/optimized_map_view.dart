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
  static const String _selectedLineValue = '__selected_line__';

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
      builder: (_) => _LineFilterSheet(mapViewModel: mapViewModel),
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
          String? selectedLineName;
          if (mapViewModel.currentFilter.mode == FilterMode.line &&
              mapViewModel.currentFilter.lineId != null) {
            for (final line in mapViewModel.lines) {
              if (line.id == mapViewModel.currentFilter.lineId) {
                selectedLineName = line.name;
                break;
              }
            }
          }

          final isFavoritesFilterEmpty =
              mapViewModel.currentFilter.mode == FilterMode.favorites &&
              !mapViewModel.isLoadingStops &&
              mapViewModel.filteredStops.isEmpty;

          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[100],
                    child: DropdownButton<String>(
                      value: mapViewModel.currentFilter.mode == FilterMode.line
                        ? _selectedLineValue
                        : mapViewModel.currentFilter.mode.name,
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
                        const DropdownMenuItem(
                          value: 'favorites',
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 16, color: AppTheme.primaryRed),
                              SizedBox(width: 8),
                              Text('Favoritas'),
                            ],
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'lines',
                          child: Row(
                            children: [
                              Icon(Icons.view_list, size: 16, color: AppTheme.primaryRed),
                              SizedBox(width: 8),
                              Text('Líneas…'),
                            ],
                          ),
                        ),
                        if (mapViewModel.currentFilter.mode == FilterMode.line)
                          DropdownMenuItem(
                            value: _selectedLineValue,
                            child: Row(
                              children: [
                                const Icon(Icons.filter_alt, size: 16, color: AppTheme.primaryRed),
                                const SizedBox(width: 8),
                                Text('Línea ${selectedLineName ?? mapViewModel.currentFilter.lineId}'),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == 'nearby') {
                          mapViewModel.setFilter(const MapFilter.nearby());
                        } else if (value == 'all') {
                          mapViewModel.setFilter(const MapFilter.all());
                        } else if (value == 'favorites') {
                          mapViewModel.refreshFavoriteStops();
                          mapViewModel.setFilter(const MapFilter.favorites());
                        } else if (value == 'lines') {
                          _showLineFilterSelector(mapViewModel);
                        }
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

class _LineFilterSheet extends StatefulWidget {
  final MapViewModel mapViewModel;

  const _LineFilterSheet({required this.mapViewModel});

  @override
  State<_LineFilterSheet> createState() => _LineFilterSheetState();
}

class _LineFilterSheetState extends State<_LineFilterSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _normalize(_query.trim());
    final filteredLines = widget.mapViewModel.lines.where((line) {
      if (normalizedQuery.isEmpty) return true;

      final matchesLineInfo =
          _normalize(line.name).contains(normalizedQuery) ||
          _normalize(line.fullName).contains(normalizedQuery) ||
          _normalize(line.description).contains(normalizedQuery);

      if (matchesLineInfo) return true;

      final matchesStops = widget.mapViewModel.stops.any(
        (stop) =>
            stop.lineIds.contains(line.id) &&
            _normalize(stop.name).contains(normalizedQuery),
      );

      return matchesStops;
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const ListTile(
              title: Text(
                'Filtrar por línea',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar línea por nombre o destino',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _query = value);
                },
                onSubmitted: (value) {
                  setState(() => _query = value);
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredLines.isEmpty
                  ? const Center(
                      child: Text('No hay líneas que coincidan'),
                    )
                  : ListView.builder(
                      itemCount: filteredLines.length,
                      itemBuilder: (context, index) {
                        final line = filteredLines[index];
                        return ListTile(
                          leading: const Icon(Icons.directions_bus, color: AppTheme.primaryRed),
                          title: Text('Línea ${line.name}'),
                          subtitle: Text(line.fullName),
                          onTap: () {
                            widget.mapViewModel.setFilter(MapFilter.line(line.id));
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
