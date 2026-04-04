import 'package:flutter/material.dart';

import '../models/tourist_place.dart';
import '../viewmodels/tourism_viewmodel.dart';

Future<void> showTourismCategorySelector({
  required BuildContext context,
  required TourismViewModel tourismViewModel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Filtro turistico',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.apps, color: Colors.blue),
                title: const Text('Todos'),
                trailing: tourismViewModel.selectedCategory == null
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  tourismViewModel.setCategory(null);
                  Navigator.pop(context);
                },
              ),
              ...TouristCategory.values.map(
                (category) => ListTile(
                  leading: const Icon(Icons.place, color: Colors.blue),
                  title: Text(tourismCategoryLabel(category)),
                  trailing: tourismViewModel.selectedCategory == category
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    tourismViewModel.setCategory(category);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
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
