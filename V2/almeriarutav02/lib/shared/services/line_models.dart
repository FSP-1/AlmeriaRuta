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
  final List<LineRouteModel> routes;
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
    this.routes = const [],
    required this.stops,
  });

  factory LineModel.fromJson(Map<String, dynamic> json) {
    final routes = (json['routes'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(LineRouteModel.fromJson)
            .toList() ??
        const <LineRouteModel>[];

    final flattenedStops = routes.isNotEmpty
        ? routes.expand((route) => route.stops).toList()
        : (json['stops'] as List?)?.whereType<Map<String, dynamic>>().map(StopModel.fromJson).toList() ?? [];

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
      routes: routes,
      stops: flattenedStops,
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
      'routes': routes.map((route) => route.toJson()).toList(),
      'stops': stops.map((stop) => stop.toJson()).toList(),
    };
  }
}

class LineRouteModel {
  final String name;
  final List<StopModel> stops;

  LineRouteModel({
    required this.name,
    required this.stops,
  });

  factory LineRouteModel.fromJson(Map<String, dynamic> json) {
    return LineRouteModel(
      name: json['name']?.toString() ?? json['ruta']?.toString() ?? 'Ruta',
      stops: (json['stops'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(StopModel.fromJson)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
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
  final bool isActive;
  final bool isDisabled;

  StopModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.zone,
    this.lineIds = const {},
    this.isActive = true,
    this.isDisabled = false,
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
      isActive: json['isActive'] ?? true,
      isDisabled: json['isDisabled'] ?? false,
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
      'isActive': isActive,
      'isDisabled': isDisabled,
    };
  }

  StopModel copyWith({
    String? id,
    String? name,
    double? lat,
    double? lon,
    String? zone,
    Set<String>? lineIds,
    bool? isActive,
    bool? isDisabled,
  }) {
    return StopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      zone: zone ?? this.zone,
      lineIds: lineIds ?? this.lineIds,
      isActive: isActive ?? this.isActive,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}

class NoticeModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'TURISMO', 'LINEA', 'PARADA', 'GENERAL'
  final String? relatedId;
  final DateTime createdAt;

  NoticeModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.createdAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'GENERAL',
      relatedId: json['relatedId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}