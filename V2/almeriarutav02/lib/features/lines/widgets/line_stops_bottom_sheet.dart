import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/line_search_utils.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../map/models/favorite_model.dart';
import '../../map/viewmodels/favorites_viewmodel.dart';
import '../../map/viewmodels/map_viewmodel.dart';
import '../../map/viewmodels/notices_viewmodel.dart';
import '../../map/views/optimized_map_view.dart';
import '../models/stop_popup_model.dart';
import '../viewmodels/lines_viewmodel.dart';
import 'line_ui_utils.dart';

class LineStopsBottomSheet {
  static void show(
    BuildContext context,
    LineModel line,
    LinesViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => FavoritesViewModel()..load(),
        child: _LineStopsContent(line: line, viewModel: viewModel),
      ),
    );
  }
}

class _LineStopsContent extends StatefulWidget {
  final LineModel line;
  final LinesViewModel viewModel;

  const _LineStopsContent({
    required this.line,
    required this.viewModel,
  });

  @override
  State<_LineStopsContent> createState() => _LineStopsContentState();
}

class _LineStopsContentState extends State<_LineStopsContent> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<StopModel> _loadedStops = const [];
  late Future<List<StopModel>> _stopsFuture;

  @override
  void initState() {
    super.initState();
    _stopsFuture = _loadStopsAndArrivals();
  }

  @override
  void didUpdateWidget(covariant _LineStopsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.id != widget.line.id) {
      _stopsFuture = _loadStopsAndArrivals();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StopModel> _filterStops(List<StopModel> stops) {
    final normalizedQuery = LineSearchUtils.normalizeText(_query.trim());
    if (normalizedQuery.isEmpty) {
      return stops;
    }

    return stops.where((stop) {
      return LineSearchUtils.normalizeText(stop.name).contains(normalizedQuery);
    }).toList();
  }

  Future<List<StopModel>> _loadStopsAndArrivals() async {
    final stops = await widget.viewModel.getLineStops(widget.line.id);
    await widget.viewModel.ensureLineArrivals(widget.line.id);
    _loadedStops = stops;
    return stops;
  }

  List<LineRouteModel> _visibleRoutes() {
    if (widget.line.routes.isNotEmpty) {
      return widget.line.routes;
    }
    return [
      LineRouteModel(
        name: widget.line.fullName,
        stops: _loadedStops,
      ),
    ];
  }

  void _openFirstMatchIfAny() {
    final filteredStops = _filterStops(_loadedStops);
    if (filteredStops.isEmpty) {
      return;
    }

    _showStopActions(
      context,
      filteredStops.first,
      widget.line,
      widget.viewModel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesViewModel>(
      builder: (context, favVM, _) {
        final isFav = favVM.isFavorite(widget.line.id, FavoriteType.line);
        final lineColor = LineUiUtils.parseLineColor(widget.line.color);

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.3,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lineColor, lineColor.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Text(
                          widget.line.name,
                          style: TextStyle(
                            color: lineColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.line.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          if (isFav) {
                            favVM.remove(widget.line.id, FavoriteType.line);
                          } else {
                            favVM.add(
                              FavoriteModel(
                                id: widget.line.id,
                                name: widget.line.fullName,
                                type: FavoriteType.line,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: AppSearchField(
                    controller: _searchController,
                    query: _query,
                    hintText: 'Buscar parada en esta línea',
                    autofocus: false,
                    onQueryChanged: (value) {
                      setState(() => _query = value);
                    },
                    onQuerySubmitted: (value) {
                      setState(() => _query = value);
                      _openFirstMatchIfAny();
                    },
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<StopModel>>(
                    future: _stopsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryRed),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final stops = snapshot.data ?? [];
                      final routes = _visibleRoutes();
                      final normalizedQuery = LineSearchUtils.normalizeText(_query.trim());

                      if (normalizedQuery.isEmpty) {
                        if (routes.isEmpty) {
                          return Center(
                            child: Text(
                              'No hay paradas disponibles',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: routes.length,
                          itemBuilder: (context, routeIndex) {
                            final route = routes[routeIndex];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: _buildRouteSection(
                                context,
                                route,
                                widget.line,
                                widget.viewModel,
                                lineColor,
                                favVM,
                              ),
                            );
                          },
                        );
                      }

                      final filteredStops = _filterStops(stops);
                      if (filteredStops.isEmpty) {
                        return Center(
                          child: Text(
                            'No hay paradas que coincidan',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: filteredStops.length,
                        itemBuilder: (context, index) {
                          final stop = filteredStops[index];
                          return _buildStopTile(
                            context: context,
                            stop: stop,
                            currentLine: widget.line,
                            linesViewModel: widget.viewModel,
                            lineColor: lineColor,
                            favVM: favVM,
                            isLast: index == filteredStops.length - 1,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteSection(
    BuildContext context,
    LineRouteModel route,
    LineModel currentLine,
    LinesViewModel linesViewModel,
    Color lineColor,
    FavoritesViewModel favVM,
  ) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        route.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${route.stops.length} paradas'),
      children: route.stops
          .asMap()
          .entries
          .map(
            (entry) => _buildStopTile(
              context: context,
              stop: entry.value,
              currentLine: currentLine,
              linesViewModel: linesViewModel,
              lineColor: lineColor,
              favVM: favVM,
              isLast: entry.key == route.stops.length - 1,
            ),
          )
          .toList(),
    );
  }

  Widget _buildStopTile({
    required BuildContext context,
    required StopModel stop,
    required LineModel currentLine,
    required LinesViewModel linesViewModel,
    required Color lineColor,
    required FavoritesViewModel favVM,
    required bool isLast,
  }) {
    final disabledStopIds = context.watch<NoticesViewModel>().disabledStops.map((s) => s.stopId).toSet();
    final isDisabled = disabledStopIds.contains(stop.id) || stop.isDisabled;
    final isStopFav = favVM.isFavorite(stop.id, FavoriteType.stop);
    final minutes = linesViewModel.getArrivalMinutes(currentLine.id, stop.id);
    final arrivalLabel = linesViewModel.formatArrivalLabel(minutes);
    final badgeBackgroundColor = minutes == null
        ? Colors.grey.withValues(alpha: 0.12)
        : (minutes <= 3
              ? Colors.red.withValues(alpha: 0.12)
              : Colors.green.withValues(alpha: 0.12));
    final badgeTextColor = minutes == null
        ? Colors.grey[700]
        : (minutes <= 3 ? Colors.red : Colors.green[800]);

    return Column(
      children: [
        InkWell(
          onTap: isDisabled ? null : () => _showStopActions(context, stop, currentLine, linesViewModel),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isDisabled ? Colors.grey : lineColor).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDisabled ? Icons.location_off : Icons.location_on,
                    color: isDisabled ? Colors.grey.shade700 : lineColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (isDisabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Parada deshabilitada',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              LineUiUtils.resolveZoneName(stop.lat, stop.lon),
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    arrivalLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isStopFav ? 'Quitar de favoritos' : 'Guardar en favoritos',
                  icon: Icon(
                    isStopFav ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: isDisabled
                      ? null
                      : () async {
                    if (isStopFav) {
                      await favVM.remove(stop.id, FavoriteType.stop);
                    } else {
                      await favVM.add(
                        FavoriteModel(
                          id: stop.id,
                          name: stop.name,
                          type: FavoriteType.stop,
                        ),
                      );
                    }
                  },
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 35),
            child: Divider(height: 1, color: Colors.grey[200]),
          ),
      ],
    );
  }

  void _showStopActions(
    BuildContext context,
    StopModel stop,
    LineModel currentLine,
    LinesViewModel linesViewModel,
  ) {
    final mapViewModel = context.read<MapViewModel>();
    final popupFuture = () async {
      if (mapViewModel.stops.isEmpty) {
        await mapViewModel.loadStops();
      }
      return linesViewModel.buildStopPopupData(
        stop,
        currentLine,
        aggregatedStops: mapViewModel.stops,
      );
    }();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<StopPopupModel>(
        future: popupFuture,
        builder: (context, snapshot) {
          final popup = snapshot.data;
          final passingLines = popup?.passingLines ?? [currentLine];
          final zoneName = popup?.zoneName ?? LineUiUtils.resolveZoneName(stop.lat, stop.lon);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Zona: $zoneName'),
                  const SizedBox(height: 12),
                  const Text(
                    'Lineas que pasan por esta parada',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(color: AppTheme.primaryRed),
                    )
                  else
                    Builder(
                      builder: (context) {
                        Map<String, int>? stopArrivals;
                        bool isFetchingArrivals = false;

                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            final canFetch = !isFetchingArrivals;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.primaryRed,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: canFetch
                                        ? () async {
                                            setModalState(() {
                                              isFetchingArrivals = true;
                                            });
                                           try {
                                              final results = await linesViewModel.fetchStopArrivals(
                                                stop.id,
                                                limit: passingLines.length,
                                              );

                                              if (context.mounted) {
                                                setModalState(() {
                                                  stopArrivals = results;
                                                });
                                              }
                                            } finally {
                                              if (context.mounted) {
                                                setModalState(() {
                                                  isFetchingArrivals = false;
                                                });
                                              }
                                            }
                                        }
                                        : null,
                                    icon: isFetchingArrivals
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.schedule),
                                    label: Text(
                                      stopArrivals == null ? 'Obtener tiempos' : 'Actualizar tiempos',
                                    ),
                                  ),
                                ),         
                                const SizedBox(height: 12),
                                Column(
                                  children: passingLines.map((line) {
                                    final minutes = stopArrivals?[line.id];

                                    final arrivalLabel =
                                        linesViewModel.formatArrivalLabel(minutes);

                                    final arrivalColor = minutes == null
                                        ? Colors.grey[700]
                                        : Colors.black;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            line.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          Text(
                                            arrivalLabel,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: arrivalColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            final rootNavigator = Navigator.of(context, rootNavigator: true);
                            Navigator.pop(context);
                            Navigator.pop(context);
                            rootNavigator.push(
                              MaterialPageRoute(
                                builder: (_) => OptimizedMapView(
                                  initialStop: stop,
                                  initialLineId: currentLine.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('Ver en el mapa'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}