import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/map/models/favorite_model.dart';
import '../../features/map/viewmodels/favorites_viewmodel.dart';

class FavoritesPanel extends StatelessWidget {
  final Future<void> Function(String lineId) onLineSelected;
  final Future<void> Function(String stopId) onStopSelected;
  final VoidCallback? onFavoritesChanged;
  final bool showTitle;
  final bool closeOnSelect;

  const FavoritesPanel({
    super.key,
    required this.onLineSelected,
    required this.onStopSelected,
    this.onFavoritesChanged,
    this.showTitle = true,
    this.closeOnSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoritesViewModel()..load(),
      child: Consumer<FavoritesViewModel>(
        builder: (context, vm, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTitle)
                const Text(
                  'Favoritos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (showTitle) const SizedBox(height: 12),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: AppTheme.primaryRed,
                        tabs: [
                          Tab(text: 'Paradas'),
                          Tab(text: 'Líneas'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildList(context, vm.stops),
                            _buildList(context, vm.lines),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<FavoriteModel> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No hay favoritos'),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final fav = items[i];
        return ListTile(
          leading: Icon(
            fav.type == FavoriteType.stop ? Icons.location_on : Icons.directions_bus,
            color: AppTheme.primaryRed,
          ),
          title: Text(
            fav.type == FavoriteType.line ? '${fav.id} - ${fav.name}' : fav.name,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            tooltip: 'Eliminar de favoritos',
            onPressed: () async {
              await context.read<FavoritesViewModel>().remove(
                    fav.id,
                    fav.type,
                  );
            },
          ),
          onTap: () async {
            if (closeOnSelect && Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }

            if (fav.type == FavoriteType.stop) {
              await onStopSelected(fav.id);
            } else {
              await onLineSelected(fav.id);
            }
          },
        );
      },
    );
  }
}