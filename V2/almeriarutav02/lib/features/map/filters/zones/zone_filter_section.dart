import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../models/zone_model.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../shared/filter_option_tile.dart';

class ZoneFilterSection extends StatelessWidget {
  final MapViewModel mapViewModel;
  final MapController? mapController;
  final VoidCallback onChanged;

  const ZoneFilterSection({
    super.key,
    required this.mapViewModel,
    required this.onChanged,
    this.mapController,
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
        leading: const Icon(Icons.map, color: Colors.green),
        title: const Text('Zona geográfica'),
        subtitle: Text(
          mapViewModel.activeZone?.name ?? 'Sin filtro de zona',
        ),
        children: [
          FilterOptionTile(
            selected: mapViewModel.activeZone == null,
            icon: Icons.layers_clear,
            color: Colors.green,
            title: 'Ninguna zona',
            onTap: () {
              mapViewModel.clearZoneFilter();
              onChanged();
            },
          ),
          ...AlmeriaZones.transportZones.map(
            (zone) => FilterOptionTile(
              selected: mapViewModel.activeZone?.id == zone.id,
              icon: Icons.location_on,
              color: Colors.green,
              title: zone.name,
              subtitle: zone.description,
              onTap: () {
                mapViewModel.setActiveZone(zone);
                mapController?.move(zone.center, 13.0);
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}
