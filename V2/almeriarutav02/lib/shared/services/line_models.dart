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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fullName': fullName,
      'description': description,
      'color': color,
      'frequency': frequency,
      'firstService': firstService,
      'lastService': lastService,
      'totalStops': totalStops,
      'stops': stops.map((stop) => stop.toJson()).toList(),
    };
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
    final rawLineIds = json['lineIds'];
    final lineIds = rawLineIds is List
        ? rawLineIds.map((id) => id.toString()).toSet()
        : <String>{};

    return StopModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? 0.0).toDouble(),
      zone: json['zone'] ?? 'A',
      lineIds: lineIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lon': lon,
      'zone': zone,
      'lineIds': lineIds.toList(),
    };
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