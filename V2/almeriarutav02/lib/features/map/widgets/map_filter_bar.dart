import 'package:flutter/material.dart';
import '../viewmodels/map_viewmodel.dart';
import '../tourism/viewmodels/tourism_viewmodel.dart';
import '../models/filter_mode.dart';

class MapFilterBar extends StatelessWidget {
  final MapViewModel mapViewModel;
  final TourismViewModel tourismViewModel;
  final VoidCallback onOpenFiltersMenu;

  const MapFilterBar({
    super.key,
    required this.mapViewModel,
    required this.tourismViewModel,
    required this.onOpenFiltersMenu,
  });

  @override
  Widget build(BuildContext context) {
    final filterLabel = switch (mapViewModel.currentFilter.mode) {
      FilterMode.nearby => 'Bus: cercanas',
      FilterMode.all => 'Bus: todas',
      FilterMode.favorites => 'Bus: favoritas',
      FilterMode.line => 'Bus: línea ${mapViewModel.currentFilter.lineId ?? '-'}',
    };

    final tourismLabel = tourismViewModel.isEnabled
        ? 'Turismo: ${tourismViewModel.selectedCategory == null ? 'todos' : 'categoría'}'
        : 'Turismo: oculto';

    final zoneLabel = mapViewModel.activeZone == null
        ? 'Zona: todas'
        : 'Zona: ${mapViewModel.activeZone!.name}';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
              foregroundColor: Colors.white,
            ),
            onPressed: onOpenFiltersMenu,
            icon: const Icon(Icons.tune),
            label: const Text('Capas y filtros del mapa'),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _FilterStatusChip(label: filterLabel),
              _FilterStatusChip(label: tourismLabel),
              _FilterStatusChip(label: zoneLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterStatusChip extends StatelessWidget {
  final String label;

  const _FilterStatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}
