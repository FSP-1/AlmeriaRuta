import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/auth_screen.dart';
import '../../auth/views/profile_view.dart';
import '../../home/views/home_view.dart';
import '../../lines/views/lines_view.dart';
import '../../notifications/views/notifications_view.dart';
import '../../tickets/views/tickets_hub_view.dart';
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
  bool _isSimpleMenuOpen = false;

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

  Future<void> _openSimpleMenu() async {
    if (_isSimpleMenuOpen) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      return;
    }

    final auth = context.read<AuthViewModel>();

    _isSimpleMenuOpen = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Cerrar menú',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (dialogContext, _, _) {
        Widget menuItem({
          required IconData icon,
          required Color color,
          required String title,
          String? subtitle,
          required VoidCallback onTap,
        }) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.16),
                foregroundColor: color,
                child: Icon(icon),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: subtitle == null ? null : Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: onTap,
            ),
          );
        }

        final panelWidth = MediaQuery.of(dialogContext).size.width * 0.86 > 360
            ? 360.0
            : MediaQuery.of(dialogContext).size.width * 0.86;

// 1. Calculamos el espacio superior (AppBar + Status Bar)
        final topOffset = kToolbarHeight + MediaQuery.of(dialogContext).padding.top;

        return Align(
          alignment: Alignment.bottomRight, // Alineamos abajo a la derecha
          child: Padding(
            padding: EdgeInsets.only(top: topOffset), // 2. Empujamos el menú bajo la cabecera
            child: Material(
              color: const Color(0xFFF8FAFC),
              elevation: 14,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                // Quitamos el bottomLeft si el menú llega hasta abajo del todo
              ),
              child: SizedBox(
                width: panelWidth,
                child: ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  children: [
                    // 3. Añadimos una cabecera con botón de cerrar explícito
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Menú',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: const Color(0xFF64748B),
                            onPressed: () => Navigator.pop(dialogContext),
                            tooltip: 'Cerrar menú',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // A partir de aquí siguen tus opciones actuales...
                    menuItem(
                      icon: Icons.home_outlined,
                      color: const Color(0xFF0EA5E9),
                      title: 'Menú completo',
                      subtitle: 'Abrir menú principal completo',
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeView(),
                          ),
                        );
                      },
                    ),
                    menuItem(
                      icon: Icons.route_outlined,
                      color: const Color(0xFFDC2626),
                      title: 'Líneas de autobús',
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LinesView()),
                        );
                      },
                    ),
                    menuItem(
                      icon: Icons.confirmation_number_outlined,
                      color: const Color(0xFF16A34A),
                      title: 'Billetes y tarjeta',
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TicketsHubView()),
                        );
                      },
                    ),
                    menuItem(
                      icon: Icons.notifications_active_outlined,
                      color: const Color(0xFF7C3AED),
                      title: 'Notificaciones',
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsView()),
                        );
                      },
                    ),
                    if (auth.isAuthenticated)
                      menuItem(
                        icon: Icons.person_outline,
                        color: const Color(0xFF0F766E),
                        title: 'Perfil',
                        subtitle: 'Ver perfil de usuario',
                        onTap: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileView()),
                          );
                        },
                      ),
                    menuItem(
                      icon: auth.isAuthenticated ? Icons.logout : Icons.login,
                      color: const Color(0xFFB42318),
                      title: auth.isAuthenticated ? 'Cerrar sesión' : 'Iniciar sesión',
                      subtitle: auth.isAuthenticated
                          ? 'Cerrar sesión actual'
                          : 'Acceder con tu cuenta',
                      onTap: () async {
                        Navigator.pop(dialogContext);

                        if (!auth.isAuthenticated) {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                          return;
                        }

                        final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Cerrar sesión'),
                                content: const Text('¿Seguro que quieres cerrar tu sesión actual?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Salir'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (!mounted || !shouldLogout) {
                          return;
                        }

                        await auth.logout();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sesión cerrada')),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
        transitionBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
            child: child,
          );
        },
      );
    } finally {
      _isSimpleMenuOpen = false;
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
                  onPressed: _openSimpleMenu,
                ),
              ],
            );
          },
        ),
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
                    _buildActiveFiltersBar(context, mapViewModel, tourismViewModel),
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
