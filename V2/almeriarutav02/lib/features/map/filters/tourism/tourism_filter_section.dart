import 'package:flutter/material.dart';

import '../../tourism/models/tourist_place.dart';
import '../../tourism/viewmodels/tourism_viewmodel.dart';
import '../shared/filter_option_tile.dart';

class TourismFilterSection extends StatelessWidget {
  final TourismViewModel tourismViewModel;
  final VoidCallback onChanged;

  const TourismFilterSection({
    super.key,
    required this.tourismViewModel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.travel_explore, color: Colors.blue),
        title: const Text('Turismo'),
        subtitle: Text(
          tourismViewModel.isEnabled
              ? (tourismViewModel.selectedCategory == null
                  ? 'Todos los puntos turísticos'
                  : tourismCategoryLabel(tourismViewModel.selectedCategory!))
              : 'Oculto',
        ),
        children: [
          SwitchListTile(
            value: tourismViewModel.isEnabled,
            title: const Text('Mostrar puntos turísticos'),
            onChanged: (value) {
              tourismViewModel.setEnabled(value);
              onChanged();
            },
          ),
          if (tourismViewModel.isEnabled) ...[
            FilterOptionTile(
              selected: tourismViewModel.selectedCategory == null,
              icon: Icons.apps,
              color: Colors.blue,
              title: 'Todas las categorías',
              onTap: () {
                tourismViewModel.setCategory(null);
                onChanged();
              },
            ),
            ...TouristCategory.values.map(
              (category) => FilterOptionTile(
                selected: tourismViewModel.selectedCategory == category,
                icon: Icons.place,
                color: Colors.blue,
                title: tourismCategoryLabel(category),
                onTap: () {
                  tourismViewModel.setCategory(category);
                  onChanged();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String tourismCategoryLabel(TouristCategory category) {
  switch (category) {
    case TouristCategory.monument:
      return 'Monumentos';
    case TouristCategory.beach:
      return 'Playas';
    case TouristCategory.museum:
      return 'Museos';
    case TouristCategory.park:
      return 'Parques';
    case TouristCategory.shopping:
      return 'Compras';
    case TouristCategory.port:
      return 'Puerto';
    case TouristCategory.leisure:
      return 'Ocio';
  }
}
