import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/filter_mode.dart';
import '../viewmodels/map_viewmodel.dart';
import '../../../shared/services/line_models.dart';
import 'map_onboarding_flow.dart';

/// Handles map initialization logic including route setup and onboarding.
class MapInitializationHandler {
  /// Initializes the map view with initial stop and filter preferences.
  static Future<void> initializeMapView(
    BuildContext context,
    MapViewModel mapViewModel, {
    required StopModel? initialStop,
    required String? initialLineId,
    required bool openWithFavoritesFilter,
  }) async {
    await mapViewModel.initialize();

    if (!context.mounted) return;

    if (initialStop != null) {
      if (!openWithFavoritesFilter) {
        await mapViewModel.showStopWithRouteFromExternal(initialStop);
      }
    }

    if (openWithFavoritesFilter) {
      await mapViewModel.refreshFavoriteStops();
      mapViewModel.clearRoute();
      mapViewModel.setFilter(const MapFilter.favorites());
    }

    if (!context.mounted) return;
    await _checkOnboarding(context);
  }

  /// Checks and shows onboarding flow if needed.
  static Future<void> _checkOnboarding(BuildContext context) async {
    await maybeShowMapOnboarding(context);
  }

  /// Centers map controller on initial stop.
  static void centerOnInitialStop(
    dynamic mapController,
    StopModel? initialStop,
  ) {
    if (initialStop != null) {
      mapController.move(LatLng(initialStop.lat, initialStop.lon), 16.0);
    }
  }
}
