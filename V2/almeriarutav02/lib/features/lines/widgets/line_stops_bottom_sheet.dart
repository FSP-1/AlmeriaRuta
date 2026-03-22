import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/line_search_utils.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../map/models/favorite_model.dart';
import '../../map/viewmodels/favorites_viewmodel.dart';
import '../../map/viewmodels/map_viewmodel.dart';
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
                    autofocus: true,
                    onQueryChanged: (value) {
                      setState(() => _query = value);
                    },
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<StopModel>>(
                    future: () async {
                      final stops = await widget.viewModel.getLineStops(widget.line.id);
                      await widget.viewModel.ensureLineArrivals(widget.line.id);
                      return stops;
                    }(),
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
                      final filteredStops = _filterStops(stops);
                      if (filteredStops.isEmpty) {
                        return Center(
                          child: Text(
                            _query.trim().isEmpty
                                ? 'No hay paradas disponibles'
                                : 'No hay paradas que coincidan',
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: filteredStops.length,
                        itemBuilder: (context, index) {
                          final stop = filteredStops[index];
                          final isLast = index == filteredStops.length - 1;
                          final minutes = widget.viewModel.getArrivalMinutes(widget.line.id, stop.id);
                          final arrivalLabel = widget.viewModel.formatArrivalLabel(minutes);
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
                                onTap: () => _showStopActions(context, stop, widget.line, widget.viewModel),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: lineColor.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.location_on,
                                          color: lineColor,
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
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                LineUiUtils.resolveZoneName(stop.lat, stop.lon),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
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
                    Column(
                      children: passingLines.map((line) {
                        linesViewModel.ensureLineArrivals(line.id);
                        final minutes = linesViewModel.getArrivalMinutes(line.id, stop.id);
                        final arrivalLabel = linesViewModel.formatArrivalLabel(minutes);
                        final arrivalColor = minutes == null
                            ? Colors.grey[700]
                            : (minutes <= 3 ? Colors.red : Colors.green[800]);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: LineUiUtils.parseLineColor(line.color).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  line.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
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