import 'package:flutter/material.dart';

import '../../viewmodels/map_viewmodel.dart';
import '../models/tourist_place.dart';
import 'tourist_bus_stops_sheet.dart';

/// Displays the main tourist place sheet with options to travel by foot or bus.
Future<void> showTouristPlaceSheet({
  required BuildContext context,
  required TouristPlace place,
  required MapViewModel mapViewModel,
  required Future<void> Function() onOpenDirections,
}) {
  final hasRouteToThisPlace =
      mapViewModel.activeRoute.isNotEmpty &&
      mapViewModel.selectedTouristPlace?.id == place.id;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(place.description),
            const SizedBox(height: 12),
            Text(
              'Distancia estimada: ${mapViewModel.calculateDistanceToPoint(place.location)} m',
            ),
            Text(
              'Tiempo estimado: ${mapViewModel.calculateWalkingTimeToPoint(place.location)} min',
            ),
            if (hasRouteToThisPlace) ...[
              const SizedBox(height: 10),
              Text(
                'Ruta activa: ${mapViewModel.routeDistanceMeters.round()} m • ${mapViewModel.routeDurationMinutes} min',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (mapViewModel.isRouteFallback)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Ruta aproximada en linea recta (fallback)',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await onOpenDirections();
                  },
                  icon: const Icon(Icons.directions_walk),
                  label: Text(hasRouteToThisPlace ? 'Recalcular a pie' : 'Ir a pie'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    showTouristBusStopsSheet(
                      context: context,
                      place: place,
                      mapViewModel: mapViewModel,
                    );
                  },
                  icon: const Icon(Icons.directions_bus),
                  label: const Text('Ir en bus'),
                ),
                if (hasRouteToThisPlace) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      mapViewModel.clearRoute();
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar ruta'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
