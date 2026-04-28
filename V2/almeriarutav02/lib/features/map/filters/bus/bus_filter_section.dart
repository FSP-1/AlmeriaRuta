import 'package:flutter/material.dart';

import '../../models/filter_mode.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../shared/filter_option_tile.dart';
import 'line_selector_sheet.dart';

class BusFilterSection extends StatelessWidget {
  final MapViewModel mapViewModel;
  final VoidCallback onChanged;

  const BusFilterSection({
    super.key,
    required this.mapViewModel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filter = mapViewModel.currentFilter;

    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.directions_bus, color: Colors.red),
        title: const Text('Paradas de bus'),
        subtitle: Text(mapViewModel.showBusStops ? 'Visibles' : 'Ocultas'),
        children: [
          SwitchListTile(
            value: mapViewModel.showBusStops,
            title: const Text('Mostrar paradas de bus'),
            onChanged: (value) {
              mapViewModel.setShowBusStops(value);
              onChanged();
            },
          ),
          if (mapViewModel.showBusStops) ...[
            FilterOptionTile(
              selected: filter.mode == FilterMode.nearby,
              icon: Icons.near_me,
              color: Colors.red,
              title: 'Cercanas',
              subtitle: 'Paradas a menos de 800 m',
              onTap: () {
                mapViewModel.setFilter(const MapFilter.nearby());
                onChanged();
              },
            ),
            FilterOptionTile(
              selected: filter.mode == FilterMode.all,
              icon: Icons.list,
              color: Colors.red,
              title: 'Todas',
              onTap: () {
                mapViewModel.setFilter(const MapFilter.all());
                onChanged();
              },
            ),
            FilterOptionTile(
              selected: filter.mode == FilterMode.favorites,
              icon: Icons.star,
              color: Colors.red,
              title: 'Favoritas',
              onTap: () {
                mapViewModel.refreshFavoriteStops();
                mapViewModel.setFilter(const MapFilter.favorites());
                onChanged();
              },
            ),
            FilterOptionTile(
              selected: filter.mode == FilterMode.line,
              icon: Icons.view_list,
              color: Colors.red,
              title: 'Línea específica',
              subtitle: filter.mode == FilterMode.line && filter.lineId != null
                  ? 'Actual: ${filter.lineId}'
                  : 'Selecciona una línea',
              onTap: () async {
                if (filter.mode != FilterMode.line) {
                  mapViewModel.setFilter(const MapFilter.all());
                }
                await showLineSelectorSheet(
                  context: context,
                  mapViewModel: mapViewModel,
                );
                onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }
}
