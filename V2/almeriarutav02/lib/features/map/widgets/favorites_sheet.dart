import 'package:flutter/material.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/widgets/favorites_panel.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FavoritesSheet extends StatelessWidget {
  final MapController mapController;
  final List<StopModel> allStops;
  final Function(String) onLineSelected;
  final Function(StopModel) onStopSelected;
  final VoidCallback onFavoritesChanged;

  const FavoritesSheet({
    super.key,
    required this.mapController,
    required this.allStops,
    required this.onLineSelected,
    required this.onStopSelected,
    required this.onFavoritesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 400,
      child: FavoritesPanel(
        closeOnSelect: true,
        onFavoritesChanged: onFavoritesChanged,
        onLineSelected: (lineId) async {
          onLineSelected(lineId);
        },
        onStopSelected: (stopId) async {
          _navigateToStop(stopId);
        },
      ),
    );
  }

  void _navigateToStop(String stopId) {
    if (allStops.isEmpty) return;
    final stop = allStops.firstWhere(
      (s) => s.id == stopId,
      orElse: () => allStops.first,
    );

    onStopSelected(stop);
    mapController.move(LatLng(stop.lat, stop.lon), 16.0);
  }
}