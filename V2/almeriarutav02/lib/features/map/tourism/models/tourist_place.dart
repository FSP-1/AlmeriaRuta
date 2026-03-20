import 'package:latlong2/latlong.dart';

enum TouristCategory {
  monument,
  beach,
  museum,
  park,
  shopping,
  port,
  leisure,
}

class TouristPlace {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  final TouristCategory category;

  const TouristPlace({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.category,
  });
}
