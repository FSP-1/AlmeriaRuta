class LineModel {
  final String id;
  final String name;
  final String fullName;
  final String description;
  final String? color;
  final String frequency;
  final String firstService;
  final String lastService;
  final int totalStops;
  final List<StopModel> stops;

  LineModel({
    required this.id,
    required this.name,
    required this.fullName,
    required this.description,
    this.color,
    required this.frequency,
    required this.firstService,
    required this.lastService,
    required this.totalStops,
    required this.stops,
  });

  factory LineModel.fromJson(Map<String, dynamic> json) {
    return LineModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      fullName: json['fullName'] ?? '',
      description: json['description'] ?? '',
      color: json['color'],
      frequency: json['frequency'] ?? '15-30 min',
      firstService: json['firstService'] ?? '06:30',
      lastService: json['lastService'] ?? '22:30',
      totalStops: json['totalStops'] ?? 0,
      stops: (json['stops'] as List?)?.map((s) => StopModel.fromJson(s)).toList() ?? [],
    );
  }
}

class StopModel {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final String zone;
  final Set<String> lineIds;

  StopModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.zone,
    this.lineIds = const {},
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? 0.0).toDouble(),
      zone: json['zone'] ?? 'A',
    );
  }

  StopModel copyWith({
    String? id,
    String? name,
    double? lat,
    double? lon,
    String? zone,
    Set<String>? lineIds,
  }) {
    return StopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      zone: zone ?? this.zone,
      lineIds: lineIds ?? this.lineIds,
    );
  }
}