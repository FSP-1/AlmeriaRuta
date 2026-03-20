import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/tourist_place.dart';

class TourismMarkersLayer extends StatelessWidget {
  final List<TouristPlace> places;
  final ValueChanged<TouristPlace> onPlaceTap;

  const TourismMarkersLayer({
    super.key,
    required this.places,
    required this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: places
          .map(
            (place) => Marker(
              point: place.location,
              width: 38,
              height: 38,
              child: GestureDetector(
                onTap: () => onPlaceTap(place),
                child: const Icon(
                  Icons.place,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
