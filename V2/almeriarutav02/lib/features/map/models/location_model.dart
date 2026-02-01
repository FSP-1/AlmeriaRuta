class LocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final String? name;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.name,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['lat']?.toDouble() ?? 0.0,
      longitude: json['lon']?.toDouble() ?? 0.0,
      address: json['display_name'] ?? '',
      name: json['name'],
    );
  }
}