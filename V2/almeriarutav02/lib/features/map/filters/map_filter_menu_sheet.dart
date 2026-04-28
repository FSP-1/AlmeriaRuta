import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../tourism/viewmodels/tourism_viewmodel.dart';
import '../viewmodels/map_viewmodel.dart';
import 'bus/bus_filter_section.dart';
import 'tourism/tourism_filter_section.dart';
import 'zones/zone_filter_section.dart';

Future<void> showMapFilterMenu({
  required BuildContext context,
  required MapViewModel mapViewModel,
  required TourismViewModel tourismViewModel,
  MapController? mapController,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.88;
      return Material(
        color: Colors.white,
        child: StatefulBuilder(
          builder: (context, setState) {
            void refresh() => setState(() {});

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const ListTile(
                    title: Text(
                      'Capas y filtros del mapa',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Configura qué se muestra y cómo se filtra.',
                    ),
                  ),
                  const Divider(height: 1),
                  BusFilterSection(
                    mapViewModel: mapViewModel,
                    onChanged: refresh,
                  ),
                  TourismFilterSection(
                    tourismViewModel: tourismViewModel,
                    onChanged: refresh,
                  ),
                  ZoneFilterSection(
                    mapViewModel: mapViewModel,
                    mapController: mapController,
                    onChanged: refresh,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.check),
                      label: const Text('Aplicar y cerrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
