import 'package:flutter/material.dart';
import '../viewmodels/map_viewmodel.dart';
import '../models/filter_mode.dart';
import '../../../core/theme/app_theme.dart';

class MapFilterBar extends StatelessWidget {
  final MapViewModel mapViewModel;
  final VoidCallback onOpenLineSelector;

  const MapFilterBar({
    super.key,
    required this.mapViewModel,
    required this.onOpenLineSelector,
  });

  static const String _selectedLineValue = '__selected_line__';

  @override
  Widget build(BuildContext context) {
    String? selectedLineName;
    if (mapViewModel.currentFilter.mode == FilterMode.line &&
        mapViewModel.currentFilter.lineId != null) {
      for (final line in mapViewModel.lines) {
        if (line.id == mapViewModel.currentFilter.lineId) {
          selectedLineName = line.name;
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[100],
      child: DropdownButton<String>(
        value: mapViewModel.currentFilter.mode == FilterMode.line
            ? _selectedLineValue
            : mapViewModel.currentFilter.mode.name,
        hint: const Text('Filtro'),
        isExpanded: true,
        items: [
          const DropdownMenuItem(
            value: 'nearby',
            child: Row(
              children: [
                Icon(Icons.near_me, size: 16, color: AppTheme.primaryRed),
                SizedBox(width: 8),
                Text('Cercanas'),
              ],
            ),
          ),
          const DropdownMenuItem(
            value: 'all',
            child: Row(
              children: [
                Icon(Icons.list, size: 16, color: AppTheme.primaryRed),
                SizedBox(width: 8),
                Text('Todas'),
              ],
            ),
          ),
          const DropdownMenuItem(
            value: 'favorites',
            child: Row(
              children: [
                Icon(Icons.star, size: 16, color: AppTheme.primaryRed),
                SizedBox(width: 8),
                Text('Favoritas'),
              ],
            ),
          ),
          const DropdownMenuItem(
            value: 'lines',
            child: Row(
              children: [
                Icon(Icons.view_list, size: 16, color: AppTheme.primaryRed),
                SizedBox(width: 8),
                Text('Líneas…'),
              ],
            ),
          ),
          if (mapViewModel.currentFilter.mode == FilterMode.line)
            DropdownMenuItem(
              value: _selectedLineValue,
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: AppTheme.primaryRed),
                  const SizedBox(width: 8),
                  Text('Línea ${selectedLineName ?? mapViewModel.currentFilter.lineId}'),
                ],
              ),
            ),
        ],
        onChanged: (value) {
          if (value == 'nearby') {
            mapViewModel.setFilter(const MapFilter.nearby());
          } else if (value == 'all') {
            mapViewModel.setFilter(const MapFilter.all());
          } else if (value == 'favorites') {
            mapViewModel.refreshFavoriteStops();
            mapViewModel.setFilter(const MapFilter.favorites());
          } else if (value == 'lines') {
            onOpenLineSelector();
          }
        },
      ),
    );
  }
}
