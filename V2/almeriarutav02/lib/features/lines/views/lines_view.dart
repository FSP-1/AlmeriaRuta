import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/widgets/favorites_panel.dart';
import '../../map/views/optimized_map_view.dart';
import '../viewmodels/lines_viewmodel.dart';
import '../widgets/line_card.dart';
import '../widgets/line_stops_bottom_sheet.dart';

class LinesView extends StatefulWidget {
  const LinesView({super.key});

  @override
  State<LinesView> createState() => _LinesViewState();
}

class _LinesViewState extends State<LinesView> {
  Future<void> _openFavoriteLine(BuildContext context, String lineId, LinesViewModel vm) async {
    LineModel? line;
    for (final item in vm.lines) {
      if (item.id == lineId) {
        line = item;
        break;
      }
    }
    if (line == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Línea favorita no encontrada')),
      );
      return;
    }

    LineStopsBottomSheet.show(context, line, vm);
  }

  Future<void> _openFavoriteStopInLines(BuildContext context, String stopId, LinesViewModel vm) async {
    StopModel? matchedStop;
    for (final line in vm.lines) {
      for (final stop in line.stops) {
        if (stop.id == stopId) {
          matchedStop = stop;
          break;
        }
      }
      if (matchedStop != null) {
        break;
      }
    }

    if (matchedStop == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parada favorita no encontrada')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OptimizedMapView(
          initialStop: matchedStop,
          openWithFavoritesFilter: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LinesViewModel()..loadLines(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Lineas de Autobus'),
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Color(0xFFFFCDD2),
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Lineas', icon: Icon(Icons.directions_bus)),
                Tab(text: 'Favoritos', icon: Icon(Icons.star)),
              ],
            ),
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

              return TabBarView(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: viewModel.lines.length,
                    itemBuilder: (context, index) {
                      final line = viewModel.lines[index];
                      return LineCard(
                        line: line,
                        onTap: () => LineStopsBottomSheet.show(context, line, viewModel),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: FavoritesPanel(
                      showTitle: false,
                      onLineSelected: (lineId) => _openFavoriteLine(context, lineId, viewModel),
                      onStopSelected: (stopId) => _openFavoriteStopInLines(context, stopId, viewModel),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
