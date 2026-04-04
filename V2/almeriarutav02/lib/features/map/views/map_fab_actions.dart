import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/filter_mode.dart';
import '../viewmodels/map_viewmodel.dart';
import '../widgets/favorites_sheet.dart';
import '../widgets/map_selection_sheets.dart';
import '../tourism/viewmodels/tourism_viewmodel.dart';

class MapFabActions {
  static void centerOnUser({
    required MapController mapController,
    required LatLng? userLocation,
  }) {
    if (userLocation != null) {
      mapController.move(userLocation, 15.0);
    } else {
      mapController.move(const LatLng(36.8381, -2.4597), 13.0);
    }
  }

  static Future<void> openFavorites({
    required BuildContext context,
    required MapViewModel mapViewModel,
    required MapController mapController,
  }) async {
    mapViewModel.refreshFavoriteStops();
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => FavoritesSheet(
        mapController: mapController,
        allStops: mapViewModel.stops,
        onLineSelected: (lineId) {
          mapViewModel.setFilter(MapFilter.line(lineId));
        },
        onStopSelected: (stop) {
          mapViewModel.clearRoute();
          mapViewModel.refreshFavoriteStops();
          mapViewModel.setFilter(const MapFilter.favorites());
        },
        onFavoritesChanged: () {
          mapViewModel.refreshFavoriteStops();
        },
      ),
    );
    mapViewModel.refreshFavoriteStops();
  }

  static Future<void> openZones({
    required BuildContext context,
    required MapViewModel mapViewModel,
    required MapController mapController,
  }) {
    return showZoneSelector(
      context: context,
      mapViewModel: mapViewModel,
      mapController: mapController,
    );
  }

  static void toggleTouristMode({
    required BuildContext context,
    required TourismViewModel tourismViewModel,
  }) {
    tourismViewModel.toggleEnabled();
    final text = tourismViewModel.isEnabled
        ? 'Modo turistico activado'
        : 'Modo turistico desactivado';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 1)),
    );
  }
}
