import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../map/models/favorite_model.dart';
import '../../map/models/zone_model.dart';
import '../../map/viewmodels/favorites_viewmodel.dart';
import '../../map/viewmodels/map_viewmodel.dart';
import '../../map/views/optimized_map_view.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../models/stop_popup_model.dart';
import '../viewmodels/lines_viewmodel.dart';

class LinesView extends StatelessWidget {
  const LinesView({super.key});

  String _resolveZoneName(double lat, double lon) {
    final zone = AlmeriaZones.findZoneByLatLng(LatLng(lat, lon));
    return zone?.name ?? 'Sin zona definida';
  }

  Color _parseLineColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return AppTheme.primaryRed;
    }

    try {
      String cleanColor = colorString.replaceFirst('#', '');
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      } else if (cleanColor.length != 8) {
        return AppTheme.primaryRed;
      }
      return Color(int.parse('0x$cleanColor'));
    } catch (_) {
      return AppTheme.primaryRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LinesViewModel()..loadLines(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lineas de Autobus'),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Consumer<LinesViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primaryRed),
                    const SizedBox(height: 24),
                    Text(
                      'Cargando lineas de Almeria...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }

            if (viewModel.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 80, color: AppTheme.primaryRed),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Error: ${viewModel.error}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => viewModel.loadLines(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: viewModel.lines.length,
              itemBuilder: (context, index) {
                final line = viewModel.lines[index];
                final lineColor = _parseLineColor(line.color);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showStops(context, line, viewModel),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: lineColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  line.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${line.firstService} - ${line.lastService}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Frecuencia: ${line.frequency}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: lineColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${line.stops.isNotEmpty ? line.stops.length : line.totalStops}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showStops(BuildContext context, LineModel line, LinesViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => FavoritesViewModel()..load(),
        child: Consumer<FavoritesViewModel>(
          builder: (context, favVM, _) {
            final isFav = favVM.isFavorite(line.id, FavoriteType.line);
            final lineColor = _parseLineColor(line.color);

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
                              line.name,
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
                              line.fullName,
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
                                favVM.remove(line.id, FavoriteType.line);
                              } else {
                                favVM.add(
                                  FavoriteModel(
                                    id: line.id,
                                    name: line.fullName,
                                    type: FavoriteType.line,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<StopModel>>(
                        future: viewModel.getLineStops(line.id),
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
                          if (stops.isEmpty) {
                            return const Center(child: Text('No hay paradas disponibles'));
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: stops.length,
                            itemBuilder: (context, index) {
                              final stop = stops[index];
                              final isLast = index == stops.length - 1;

                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () => _showStopActions(context, stop, line, viewModel),
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
                                                    _resolveZoneName(stop.lat, stop.lon),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
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
        ),
      ),
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
          final zoneName = popup?.zoneName ?? _resolveZoneName(stop.lat, stop.lon);

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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: passingLines
                          .map(
                            (line) => Chip(
                              label: Text(line.name),
                              backgroundColor: _parseLineColor(line.color).withValues(alpha: 0.15),
                            ),
                          )
                          .toList(),
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
