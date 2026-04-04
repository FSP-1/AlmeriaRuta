import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/zone_model.dart';
import '../viewmodels/map_viewmodel.dart';

Future<void> showZoneSelector({
  required BuildContext context,
  required MapViewModel mapViewModel,
  required MapController mapController,
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
                  'Filtrar por zona',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.layers_clear, color: Colors.grey),
                title: const Text('Todas las zonas'),
                onTap: () {
                  mapViewModel.clearZoneFilter();
                  Navigator.pop(context);
                },
              ),
              ...AlmeriaZones.transportZones.map(
                (zone) => ListTile(
                  leading: const Icon(Icons.map, color: Colors.green),
                  title: Text(zone.name),
                  subtitle: Text(zone.description),
                  onTap: () {
                    mapViewModel.setActiveZone(zone);
                    mapController.move(zone.center, 13.0);
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
