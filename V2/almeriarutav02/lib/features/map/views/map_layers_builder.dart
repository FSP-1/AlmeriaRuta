import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/map_viewmodel.dart';
import '../tourism/viewmodels/tourism_viewmodel.dart';
import '../tourism/models/tourist_place.dart';
import '../tourism/widgets/tourism_markers_layer.dart';
import '../../../shared/services/line_models.dart';

/// Builds all map layers (polygons, polylines, markers).
class MapLayersBuilder {
  /// Builds the complete list of map layers based on current map state.
  static List<Widget> buildMapLayers({
    required MapViewModel mapViewModel,
    required TourismViewModel tourismViewModel,
    required double currentZoom,
    required bool isTouristBusRouteOnlyMode,
    required bool isWalkingRouteMode,
    required List<StopModel> markersToRender,
    required Function(StopModel) onStopMarkerTap,
    required Function(TouristPlace) onTouristMarkerTap,
    required VoidCallback onTouristPlaceMarkerTap,
  }) {
    return [
      // Base tile layer
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.almeriarutav02',
      ),

      // Active zone polygon
      _buildActiveZoneLayer(mapViewModel, isTouristBusRouteOnlyMode),

      // Active route polyline
      if (mapViewModel.activeRoute.isNotEmpty)
        PolylineLayer(
          polylines: [
            Polyline(
              points: mapViewModel.activeRoute,
              strokeWidth: 4,
              color: Colors.blue,
            ),
          ],
        ),

      // Stop markers and user location
      if (currentZoom >= 12 && !mapViewModel.isLoadingStops)
        MarkerLayer(
          markers: _buildMarkers(
            mapViewModel: mapViewModel,
            isTouristBusRouteOnlyMode: isTouristBusRouteOnlyMode,
            markersToRender: markersToRender,
            onStopMarkerTap: onStopMarkerTap,
            onTouristPlaceMarkerTap: onTouristPlaceMarkerTap,
          ),
        ),

      // Tourism markers layer
      if (tourismViewModel.isEnabled && !isTouristBusRouteOnlyMode)
        TourismMarkersLayer(
          places: tourismViewModel.filteredPlaces,
          onPlaceTap: onTouristMarkerTap,
        ),

      // Attribution
      RichAttributionWidget(
        attributions: [
          TextSourceAttribution(
            '© OpenStreetMap contributors',
            onTap: () {},
          ),
        ],
      ),
    ];
  }

  /// Builds the active zone polygon layer.
  static Widget _buildActiveZoneLayer(
    MapViewModel mapViewModel,
    bool isTouristBusRouteOnlyMode,
  ) {
    final hasActiveZone = mapViewModel.activeZone != null;
    return PolygonLayer(
      polygons: hasActiveZone && !isTouristBusRouteOnlyMode
          ? <Polygon<Object>>[
              Polygon<Object>(
                points: mapViewModel.activeZone!.polygon,
                color: Colors.green.withValues(alpha: 0.08),
                borderColor: Colors.green.withValues(alpha: 0.7),
                borderStrokeWidth: 2,
              ),
            ]
          : <Polygon<Object>>[],
    );
  }

  /// Builds all markers (stops, user, tourist place).
  static List<Marker> _buildMarkers({
    required MapViewModel mapViewModel,
    required bool isTouristBusRouteOnlyMode,
    required List<StopModel> markersToRender,
    required Function(StopModel) onStopMarkerTap,
    required VoidCallback onTouristPlaceMarkerTap,
  }) {
    final markers = <Marker>[];

    // Stop markers
    for (final stop in markersToRender) {
      markers.add(
        Marker(
          point: LatLng(stop.lat, stop.lon),
          width: 30,
          height: 30,
          child: GestureDetector(
            onTap: () => onStopMarkerTap(stop),
            child: Container(
              decoration: BoxDecoration(
                color: isTouristBusRouteOnlyMode
                    ? Colors.blue
                    : (stop.lineIds.length > 1
                        ? Colors.purple
                        : AppTheme.primaryRed),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      );
    }

    // User location marker
    if (mapViewModel.userLocation != null) {
      markers.add(
        Marker(
          point: mapViewModel.userLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Tourist place marker (in tourist bus route mode)
    if (isTouristBusRouteOnlyMode && mapViewModel.selectedTouristPlace != null) {
      markers.add(
        Marker(
          point: mapViewModel.selectedTouristPlace!.location,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: mapViewModel.activeTouristBusRoutePlan == null ? null : onTouristPlaceMarkerTap,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.place,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }
}
