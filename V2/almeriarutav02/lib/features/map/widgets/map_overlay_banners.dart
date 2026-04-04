import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/zone_model.dart';

class FavoritesEmptyBanner extends StatelessWidget {
  const FavoritesEmptyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.star_border, color: AppTheme.primaryRed),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No tienes paradas favoritas. Anade una desde el detalle de parada.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveZoneBanner extends StatelessWidget {
  final ZoneModel zone;
  final VoidCallback onClear;

  const ActiveZoneBanner({
    super.key,
    required this.zone,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.map, color: Colors.green),
        title: Text('Zona activa: ${zone.name}'),
        subtitle: Text(zone.description),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClear,
        ),
      ),
    );
  }
}

class TourismModeBanner extends StatelessWidget {
  final String title;
  final VoidCallback onTune;

  const TourismModeBanner({
    super.key,
    required this.title,
    required this.onTune,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.tour, color: Colors.blue),
        title: Text(title),
        trailing: IconButton(
          icon: const Icon(Icons.tune, color: Colors.blue),
          onPressed: onTune,
        ),
      ),
    );
  }
}
