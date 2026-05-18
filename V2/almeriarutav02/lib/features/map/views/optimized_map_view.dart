import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../models/filter_mode.dart';
import '../viewmodels/notices_viewmodel.dart';
import '../viewmodels/map_viewmodel.dart';
import '../filters/map_filter_menu_sheet.dart';
import '../widgets/map_floating_buttons.dart';
import '../widgets/notices_marquee_widget.dart';
import '../widgets/map_simple_menu_overlay.dart';
import '../widgets/stop_info_sheet.dart';
import '../widgets/tourist_bus_stop_info_sheet.dart';
import '../tourism/viewmodels/tourism_viewmodel.dart';
import '../tourism/models/tourist_place.dart';
import '../tourism/widgets/tourist_bus_stops_sheet.dart';
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
  bool _isSimpleMenuOpen = false;
  bool _isRefreshingLocation = false;

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

  void _toggleSimpleMenu() {
    setState(() {
      _isSimpleMenuOpen = !_isSimpleMenuOpen;
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
        onGetBusDirections: () {
          // Reuse tourist bus flow: create a synthetic TouristPlace from the stop
          final place = TouristPlace(
            id: 'stop-${stop.id}',
            name: stop.name,
            location: LatLng(stop.lat, stop.lon),
            description: 'Parada ${stop.name}',
            category: TouristCategory.leisure,
          );
          Navigator.pop(ctx);
          showTouristBusStopsSheet(context: context, place: place, mapViewModel: vm);
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

  Future<void> _openDirectionsByProfile(MapViewModel vm, StopModel stop, String profile) async {
    if (vm.userLocation == null) return;
    try {
      final route = await vm.getRoute(vm.userLocation!, LatLng(stop.lat, stop.lon), profile: profile);
      vm.setRoute(stop, route);
    } catch (_) {
      vm.setRoute(stop, [vm.userLocation!, LatLng(stop.lat, stop.lon)]);
    }
  }

  Widget _buildActiveFiltersBar(
    BuildContext context,
    MapViewModel mapViewModel,
    TourismViewModel tourismViewModel,
  ) {
    final busLabel = switch (mapViewModel.currentFilter.mode) {
      FilterMode.nearby => 'Bus: cercanas',
      FilterMode.all => 'Bus: todas',
      FilterMode.favorites => 'Bus: favoritas',
      FilterMode.line => 'Bus: linea ${mapViewModel.currentFilter.lineId ?? '-'}',
    };

    final tourismLabel = tourismViewModel.isEnabled
        ? 'Turismo: ${tourismViewModel.selectedCategory == null ? 'todos' : 'categoria'}'
        : 'Turismo: oculto';

    final zoneLabel = mapViewModel.activeZone == null
        ? 'Zona: todas'
        : 'Zona: ${mapViewModel.activeZone!.name}';

    Widget statusChip(String label) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            statusChip(busLabel),
            statusChip(tourismLabel),
            statusChip(zoneLabel),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer2<MapViewModel, TourismViewModel>(
          builder: (context, mapViewModel, tourismViewModel, _) {
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
                  icon: Icon(_showSearch ? Icons.close : Icons.search),
                  onPressed: () => setState(() => _showSearch = !_showSearch),
                ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () => showMapFilterMenu(
                    context: context,
                    mapViewModel: mapViewModel,
                    tourismViewModel: tourismViewModel,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: _toggleSimpleMenu,
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer2<MapViewModel, TourismViewModel>(
        builder: (context, mapViewModel, tourismViewModel, _) {
          final disabledStopIds = context.watch<NoticesViewModel>().disabledStops.map((s) => s.stopId).toSet();
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

            final markersWithDisabledState = markersToRender
              .map((stop) => stop.copyWith(isDisabled: disabledStopIds.contains(stop.id)))
              .toList();

          return Stack(
            children: [
              Column(
                children: [
                  NoticesMarqueeWidget(
                    onTap: () {
                      final noticesVM = context.read<NoticesViewModel>();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => NoticesSummarySheet(noticesVM: noticesVM),
                      );
                    },
                  ),
                  if (!isTouristBusMode)
                    _buildActiveFiltersBar(context, mapViewModel, tourismViewModel),
                  Expanded(
                    child: MapWidget(
                      mapController: _mapController,
                      currentZoom: _currentZoom,
                      mapViewModel: mapViewModel,
                      tourismViewModel: tourismViewModel,
                      isTouristBusRouteOnlyMode: isTouristBusMode,
                      isWalkingRouteMode: isWalkingMode,
                      markersToRender: markersWithDisabledState,
                      disabledStops: context.watch<NoticesViewModel>().disabledStops,
                      onZoomChanged: (z) => setState(() => _currentZoom = z),
                      onStopTap: (stop) => _onStopTap(context, stop, mapViewModel),
                      onTouristBusStopTap: (stop) =>
                          _onTouristBusStopTap(context, stop, mapViewModel),
                    ),
                  ),
                ],
              ),
              if (_isSimpleMenuOpen)
                MapSimpleMenuOverlay(
                  isOpen: _isSimpleMenuOpen,
                  onClose: _toggleSimpleMenu,
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
        builder: (context, mapViewModel, _) => _isSimpleMenuOpen
            ? const SizedBox.shrink()
            : MapFloatingButtons(
                hasActiveRoute: mapViewModel.activeRoute.isNotEmpty,
                onClearRoute: mapViewModel.clearRoute,
                onMyLocation: () {
                  if (_isRefreshingLocation) return;
                  setState(() => _isRefreshingLocation = true);

                  showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryRed),
                    ),
                  );
                  
                  final nav = Navigator.of(context, rootNavigator: true);

                    mapViewModel.refreshCurrentLocation().whenComplete(() {
                      if (!mounted) return;

                      if (nav.canPop()) {
                        nav.pop();
                      }

                      setState(() => _isRefreshingLocation = false);
                    }).then((_) {
                      if (!mounted) return;

                      MapFabActions.centerOnUser(
                        mapController: _mapController,
                        userLocation: mapViewModel.userLocation,
                      );
                    });
                },
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
