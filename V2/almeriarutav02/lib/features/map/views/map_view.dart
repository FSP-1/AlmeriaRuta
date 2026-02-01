import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import '../viewmodels/map_viewmodel.dart';
import '../models/location_model.dart';
import '../../../core/theme/app_theme.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapViewModel(),
      child: const _MapViewContent(),
    );
  }
}

class _MapViewContent extends StatelessWidget {
  const _MapViewContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Consumer<MapViewModel>(
        builder: (context, viewModel, child) {
          return FlutterLocationPicker(
            initPosition: const LatLong(36.8381, -2.4597), // Centro de Almería
            initZoom: 13,
            minZoomLevel: 10,
            maxZoomLevel: 18,
            trackMyPosition: true,
            searchBarBackgroundColor: Colors.white,
            selectedLocationButtonTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            mapLanguage: 'es',
            selectLocationButtonText: 'Confirmar Ubicación',
            selectLocationButtonLeadingIcon: const Icon(Icons.location_on),
            userAgent: 'AlmeriaRuta/1.0.0',
            onError: (error) => viewModel.setError(error.toString()),
            onPicked: (pickedData) {
              final location = LocationModel(
                latitude: pickedData.latLong.latitude,
                longitude: pickedData.latLong.longitude,
                address: pickedData.address,
              );
              viewModel.setSelectedLocation(location);
              Navigator.pop(context, location);
            },
            onChanged: (pickedData) {
              final location = LocationModel(
                latitude: pickedData.latLong.latitude,
                longitude: pickedData.latLong.longitude,
                address: pickedData.address,
              );
              viewModel.setSelectedLocation(location);
            },
            showContributorBadgeForOSM: true,
          );
        },
      ),
    );
  }
}