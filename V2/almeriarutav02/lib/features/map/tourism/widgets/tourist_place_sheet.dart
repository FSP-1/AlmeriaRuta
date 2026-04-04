import 'package:flutter/material.dart';

import '../../viewmodels/map_viewmodel.dart';
import '../models/tourist_place.dart';

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
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await onOpenDirections();
                    },
                    icon: const Icon(Icons.directions_walk),
                    label: Text(hasRouteToThisPlace ? 'Recalcular' : 'Como llegar'),
                  ),
                ),
                if (hasRouteToThisPlace) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      mapViewModel.clearRoute();
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar'),
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

Future<void> openTouristDirections({
  required BuildContext context,
  required MapViewModel mapViewModel,
  required TouristPlace place,
}) async {
  if (mapViewModel.userLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo obtener tu ubicacion actual')),
    );
    return;
  }

  final result = await mapViewModel.getRouteResult(
    mapViewModel.userLocation!,
    place.location,
  );

  if (!context.mounted) return;

  mapViewModel.setTouristRoute(place, result);

  final fallbackText = result.isFallback ? ' (fallback)' : '';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Ruta a ${place.name}: ${result.distanceMeters.round()} m · ${result.durationMinutes} min$fallbackText',
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
