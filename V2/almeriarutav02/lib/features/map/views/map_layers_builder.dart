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
          polylines: _buildRoutePolylines(mapViewModel),
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

  static List<Polyline> _buildRoutePolylines(MapViewModel mapViewModel) {
    if (mapViewModel.activeTouristBusRoutePlan != null) {
      final polylines = <Polyline>[];

      if (mapViewModel.touristWalkToBoardRoute.isNotEmpty) {
        polylines.add(
          Polyline(
            points: mapViewModel.touristWalkToBoardRoute,
            strokeWidth: 4,
            color: Colors.deepOrange,
            borderColor: Colors.white,
            borderStrokeWidth: 1,
          ),
        );
      }

      polylines.addAll(_buildTouristBusSegmentPolylines(mapViewModel));

      if (mapViewModel.touristWalkToPlaceRoute.isNotEmpty) {
        polylines.add(
          Polyline(
            points: mapViewModel.touristWalkToPlaceRoute,
            strokeWidth: 4,
            color: Colors.green,
            borderColor: Colors.white,
            borderStrokeWidth: 1,
          ),
        );
      }

      return polylines;
    }

    return [
      Polyline(
        points: mapViewModel.activeRoute,
        strokeWidth: 4,
        color: Colors.blue,
        borderColor: Colors.white,
        borderStrokeWidth: 1,
      ),
    ];
  }

  static List<Polyline> _buildTouristBusSegmentPolylines(MapViewModel mapViewModel) {
    final plan = mapViewModel.activeTouristBusRoutePlan;
    if (plan == null) return const [];

    final polylines = <Polyline>[];
    final palette = <Color>[
      Colors.blue,
      Colors.deepPurple,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
    ];

    for (var index = 0; index < plan.segments.length; index++) {
      final segment = plan.segments[index];
      final color = palette[index % palette.length];
      final points = segment.routeStops
          .map((stop) => LatLng(stop.lat, stop.lon))
          .toList();

      if (points.length < 2) continue;

      polylines.add(
        Polyline(
          points: points,
          strokeWidth: 5.5,
          color: color,
          borderColor: Colors.white,
          borderStrokeWidth: 1.5,
        ),
      );
    }

    return polylines;
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
    final hasTouristBusPlan = mapViewModel.activeTouristBusRoutePlan != null;
    final transferStopIds = hasTouristBusPlan
      ? mapViewModel.activeTouristBusRoutePlan!.segments
        .skip(1)
        .map((segment) => segment.boardingStop.id)
        .toSet()
      : <String>{};

    // Stop markers
    for (var index = 0; index < markersToRender.length; index++) {
      final stop = markersToRender[index];
      final isTouristRouteStop = isTouristBusRouteOnlyMode && hasTouristBusPlan;
      final isFirstRouteStop = isTouristRouteStop && index == 0;
      final isLastRouteStop = isTouristRouteStop && index == markersToRender.length - 1;
      final isTransferStop = isTouristRouteStop && transferStopIds.contains(stop.id);
      final isIntermediateRouteStop = isTouristRouteStop && !isFirstRouteStop && !isLastRouteStop && !isTransferStop;

      final markerSize = isIntermediateRouteStop ? 12.0 : (isTransferStop ? 34.0 : 30.0);
      final iconSize = isIntermediateRouteStop ? 8.0 : (isTransferStop ? 18.0 : 16.0);
      final markerColor = isIntermediateRouteStop
          ? Colors.blue.withValues(alpha: 0.75)
          : (isFirstRouteStop
              ? Colors.deepOrange
          : (isLastRouteStop
            ? Colors.green
            : (isTransferStop
              ? Colors.deepPurple
              : (stop.lineIds.length > 1 ? Colors.purple : AppTheme.primaryRed))));

      markers.add(
        Marker(
          point: LatLng(stop.lat, stop.lon),
          width: markerSize,
          height: markerSize,
          child: GestureDetector(
            onTap: () => onStopMarkerTap(stop),
            child: Container(
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isIntermediateRouteStop ? 1 : 2,
                ),
              ),
              child: Icon(
                isIntermediateRouteStop
                    ? Icons.circle
                    : (isFirstRouteStop
                        ? Icons.fmd_good
                        : (isLastRouteStop
                            ? Icons.flag
                            : (isTransferStop ? Icons.swap_calls : Icons.directions_bus))),
                color: Colors.white,
                size: iconSize,
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
