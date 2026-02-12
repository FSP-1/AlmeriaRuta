enum FavoriteType {
  stop,
  line,
}

class FavoriteModel {
  final String id;
  final String name;
  final FavoriteType type;

  FavoriteModel({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
      };

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'],
      name: json['name'],
      type: FavoriteType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
    );
  }
}