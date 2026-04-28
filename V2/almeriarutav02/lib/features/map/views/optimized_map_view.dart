import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../models/filter_mode.dart';
import '../viewmodels/map_viewmodel.dart';
import '../filters/map_filter_menu_sheet.dart';
import '../widgets/map_floating_buttons.dart';
import '../widgets/stop_info_sheet.dart';
import '../widgets/tourist_bus_stop_info_sheet.dart';
import '../tourism/viewmodels/tourism_viewmodel.dart';
import 'map_fab_actions.dart';
import 'map_initialization.dart';
import 'map_onboarding_flow.dart';
import 'map_overlays_builder.dart';
import 'map_widget.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await MapInitializationHandler.initializeMapView(
        context,
        context.read<MapViewModel>(),
        initialStop: widget.initialStop,
        initialLineId: widget.initialLineId,
        openWithFavoritesFilter: widget.openWithFavoritesFilter,
      );
      if (mounted) {
        MapInitializationHandler.centerOnInitialStop(_mapController, widget.initialStop);
      }
    });
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onStopTap(BuildContext context, StopModel stop, MapViewModel vm) {
    if (vm.activeRoute.isNotEmpty && vm.targetStop != null) {
      _openDirections(vm, stop);
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StopInfoSheet(
        stop: stop,
        userLocation: vm.userLocation,
        onFavoritesChanged: vm.refreshFavoriteStops,
        onGetDirections: () {
          _openDirections(vm, stop);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _onTouristBusStopTap(BuildContext context, StopModel stop, MapViewModel vm) {
    showModalBottomSheet(
      context: context,
      builder: (_) => TouristBusStopInfoSheet(
        stop: stop,
        plan: vm.activeTouristBusRoutePlan,
        selectedPlace: vm.selectedTouristPlace,
      ),
    );
  }

  Future<void> _openDirections(MapViewModel vm, StopModel stop) async {
    if (vm.userLocation == null) return;
    try {
      final route = await vm.getRoute(vm.userLocation!, LatLng(stop.lat, stop.lon));
      vm.setRoute(stop, route);
    } catch (_) {
      vm.setRoute(stop, [vm.userLocation!, LatLng(stop.lat, stop.lon)]);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _MapAppBar(
        showSearch: _showSearch,
        onToggleSearch: () => setState(() => _showSearch = !_showSearch),
      ),
      body: Consumer2<MapViewModel, TourismViewModel>(
        builder: (context, mapViewModel, tourismViewModel, _) {
          final isTouristBusMode =
              mapViewModel.isTouristBusRouteOnlyMode && mapViewModel.activeRoute.isNotEmpty;
          final isWalkingMode =
              mapViewModel.activeRoute.isNotEmpty && !isTouristBusMode;
          final isFavoritesEmpty =
              mapViewModel.currentFilter.mode == FilterMode.favorites &&
              !mapViewModel.isLoadingStops &&
              mapViewModel.filteredStops.isEmpty;

          final markersToRender = isTouristBusMode
              ? mapViewModel.touristBusRouteStops
              : (mapViewModel.activeRoute.isNotEmpty && mapViewModel.targetStop != null
                  ? [mapViewModel.targetStop!]
                  : mapViewModel.filteredStops);

          return Stack(
            children: [
              Column(
                children: [
                  if (!isTouristBusMode)
                    MapOverlaysBuilder.buildFilterBar(
                      mapViewModel,
                      tourismViewModel,
                      () => showMapFilterMenu(
                        context: context,
                        mapViewModel: mapViewModel,
                        tourismViewModel: tourismViewModel,
                      ),
                    ),
                  Expanded(
                    child: MapWidget(
                      mapController: _mapController,
                      currentZoom: _currentZoom,
                      mapViewModel: mapViewModel,
                      tourismViewModel: tourismViewModel,
                      isTouristBusRouteOnlyMode: isTouristBusMode,
                      isWalkingRouteMode: isWalkingMode,
                      markersToRender: markersToRender,
                      onZoomChanged: (z) => setState(() => _currentZoom = z),
                      onStopTap: (stop) => _onStopTap(context, stop, mapViewModel),
                      onTouristBusStopTap: (stop) =>
                          _onTouristBusStopTap(context, stop, mapViewModel),
                    ),
                  ),
                ],
              ),
              MapOverlaysBuilder.buildSearchOverlay(
                _showSearch,
                (location) {
                  _mapController.move(LatLng(location.latitude, location.longitude), 15.0);
                  setState(() => _showSearch = false);
                },
              ),
              ...MapOverlaysBuilder.buildPositionedOverlays(
                mapViewModel: mapViewModel,
                isFavoritesFilterEmpty: isFavoritesEmpty,
                isTouristBusRouteOnlyMode: isTouristBusMode,
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<MapViewModel>(
        builder: (context, mapViewModel, _) => MapFloatingButtons(
          hasActiveRoute: mapViewModel.activeRoute.isNotEmpty,
          onClearRoute: mapViewModel.clearRoute,
          onMyLocation: () => MapFabActions.centerOnUser(
            mapController: _mapController,
            userLocation: mapViewModel.userLocation,
          ),
          onFavorites: () => MapFabActions.openFavorites(
            context: context,
            mapViewModel: mapViewModel,
            mapController: _mapController,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ── AppBar widget ─────────────────────────────────────────────────────────────

class _MapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showSearch;
  final VoidCallback onToggleSearch;

  const _MapAppBar({required this.showSearch, required this.onToggleSearch});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Mapa de Almería'),
      backgroundColor: AppTheme.primaryRed,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => showMapTutorialFlow(context: context, isFirstTime: false),
        ),
        IconButton(
          icon: Icon(showSearch ? Icons.close : Icons.search),
          onPressed: onToggleSearch,
        ),
      ],
    );
  }
}
