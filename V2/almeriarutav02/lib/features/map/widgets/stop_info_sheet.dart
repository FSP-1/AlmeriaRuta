import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../viewmodels/favorites_viewmodel.dart';
import '../models/favorite_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';

class StopInfoSheet extends StatelessWidget {
  final StopModel stop;
  final LatLng? userLocation;
  final VoidCallback? onGetDirections;

  const StopInfoSheet({
    super.key,
    required this.stop,
    this.userLocation,
    this.onGetDirections,
  });

  String _calculateDistance() {
    if (userLocation == null) return '---';
    
    final distance = Geolocator.distanceBetween(
      userLocation!.latitude,
      userLocation!.longitude,
      stop.lat,
      stop.lon,
    );
    
    return distance.round().toString();
  }

  String _calculateWalkingTime() {
    if (userLocation == null) return '---';
    
    final distance = Geolocator.distanceBetween(
      userLocation!.latitude,
      userLocation!.longitude,
      stop.lat,
      stop.lon,
    );
    
    // Velocidad promedio caminando: 5 km/h = 1.39 m/s
    final timeInSeconds = distance / 1.39;
    final timeInMinutes = (timeInSeconds / 60).round();
    
    return timeInMinutes.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoritesViewModel()..load(),
      child: Consumer<FavoritesViewModel>(
        builder: (context, favVM, _) {
          final isFav = favVM.isFavorite(stop.id, FavoriteType.stop);
          
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.primaryRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stop.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                      onPressed: () {
                        if (isFav) {
                          favVM.remove(stop.id, FavoriteType.stop);
                        } else {
                          favVM.add(
                            FavoriteModel(
                              id: stop.id,
                              name: stop.name,
                              type: FavoriteType.stop,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Líneas: ${stop.lineIds.join(", ")}'),
                if (userLocation != null) ...[
                  const SizedBox(height: 8),
                  Text('Distancia: ${_calculateDistance()} m'),
                  Text('Tiempo caminando: ${_calculateWalkingTime()} min'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: onGetDirections,
                    icon: const Icon(Icons.directions),
                    label: const Text('Cómo llegar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
