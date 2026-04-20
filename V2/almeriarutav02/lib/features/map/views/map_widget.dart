import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/services/line_models.dart';
import '../viewmodels/map_viewmodel.dart';
import '../tourism/viewmodels/tourism_viewmodel.dart';
import '../tourism/widgets/tourist_bus_route_sheet.dart';
import '../tourism/widgets/tourist_directions_handler.dart';
import '../tourism/widgets/tourist_place_sheet_main.dart';
import 'map_layers_builder.dart';

/// The core FlutterMap widget with all marker/route callbacks wired up.
class MapWidget extends StatelessWidget {
  final MapController mapController;
  final double currentZoom;
  final MapViewModel mapViewModel;
  final TourismViewModel tourismViewModel;
  final bool isTouristBusRouteOnlyMode;
  final bool isWalkingRouteMode;
  final List<StopModel> markersToRender;
  final ValueChanged<double> onZoomChanged;
  final void Function(StopModel stop) onStopTap;
  final void Function(StopModel stop) onTouristBusStopTap;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.currentZoom,
    required this.mapViewModel,
    required this.tourismViewModel,
    required this.isTouristBusRouteOnlyMode,
    required this.isWalkingRouteMode,
    required this.markersToRender,
    required this.onZoomChanged,
    required this.onStopTap,
    required this.onTouristBusStopTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: const LatLng(36.8381, -2.4597),
        initialZoom: 13.0,
        minZoom: 10.0,
        maxZoom: 18.0,
        onPositionChanged: (position, _) => onZoomChanged(position.zoom),
      ),
      children: MapLayersBuilder.buildMapLayers(
        mapViewModel: mapViewModel,
        tourismViewModel: tourismViewModel,
        currentZoom: currentZoom,
        isTouristBusRouteOnlyMode: isTouristBusRouteOnlyMode,
        isWalkingRouteMode: isWalkingRouteMode,
        markersToRender: markersToRender,
        onStopMarkerTap: (stop) {
          if (isTouristBusRouteOnlyMode) {
            onTouristBusStopTap(stop);
            return;
          }
          onStopTap(stop);
        },
        onTouristMarkerTap: (place) async {
          if (isWalkingRouteMode) {
            await openTouristDirections(
              context: context,
              mapViewModel: mapViewModel,
              place: place,
            );
            return;
          }
          showTouristPlaceSheet(
            context: context,
            place: place,
            mapViewModel: mapViewModel,
            onOpenDirections: () => openTouristDirections(
              context: context,
              mapViewModel: mapViewModel,
              place: place,
            ),
          );
        },
        onTouristPlaceMarkerTap: () => _onTouristPlaceMarkerTap(context),
      ),
    );
  }

  void _onTouristPlaceMarkerTap(BuildContext context) {
    final plan = mapViewModel.activeTouristBusRoutePlan;
    final place = mapViewModel.selectedTouristPlace;
    if (plan == null || place == null) return;
    showTouristBusRouteSheet(context: context, place: place, plan: plan);
  }
}
