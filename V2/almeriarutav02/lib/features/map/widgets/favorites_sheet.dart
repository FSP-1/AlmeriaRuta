import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/favorites_viewmodel.dart';
import '../models/favorite_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FavoritesSheet extends StatelessWidget {
  final MapController mapController;
  final List<StopModel> allStops;
  final Function(String) onLineSelected;

  const FavoritesSheet({
    super.key,
    required this.mapController,
    required this.allStops,
    required this.onLineSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoritesViewModel()..load(),
      child: Consumer<FavoritesViewModel>(
        builder: (context, vm, _) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Favoritos",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: AppTheme.primaryRed,
                          tabs: [
                            Tab(text: "Paradas"),
                            Tab(text: "Líneas"),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildList(vm.stops),
                              _buildList(vm.lines),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(List<FavoriteModel> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text("No hay favoritos"),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final fav = items[i];
        return ListTile(
          leading: Icon(
            fav.type == FavoriteType.stop
                ? Icons.location_on
                : Icons.directions_bus,
            color: AppTheme.primaryRed,
          ),
          title: Text(fav.name),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            Navigator.pop(context);
            if (fav.type == FavoriteType.stop) {
              _navigateToStop(fav.id);
            } else {
              onLineSelected(fav.id);
            }
          },
        );
      },
    );
  }

  void _navigateToStop(String stopId) {
    final stop = allStops.firstWhere(
      (s) => s.id == stopId,
      orElse: () => allStops.first,
    );
    
    mapController.move(LatLng(stop.lat, stop.lon), 16.0);
  }
}