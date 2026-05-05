import 'package:flutter/material.dart';
import '../viewmodels/map_viewmodel.dart';
import '../tourism/viewmodels/tourism_viewmodel.dart';

class MapFilterBar extends StatelessWidget {
  final MapViewModel mapViewModel;
  final TourismViewModel tourismViewModel;
  final VoidCallback onOpenFiltersMenu;
  final VoidCallback onOpenSimpleMenu;

  const MapFilterBar({
    super.key,
    required this.mapViewModel,
    required this.tourismViewModel,
    required this.onOpenFiltersMenu,
    required this.onOpenSimpleMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB42318),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: onOpenFiltersMenu,
                  child: const Icon(Icons.tune),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                ),
                onPressed: onOpenSimpleMenu,
                child: const Icon(Icons.menu),
              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
