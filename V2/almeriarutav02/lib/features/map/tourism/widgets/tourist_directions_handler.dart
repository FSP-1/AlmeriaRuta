import 'package:flutter/material.dart';

import '../../viewmodels/map_viewmodel.dart';
import '../models/tourist_place.dart';

/// Handles opening walking directions to a tourist place.
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
