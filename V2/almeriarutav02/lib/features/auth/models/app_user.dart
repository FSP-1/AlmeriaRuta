class AppUser {
  final int? id;
  final String? email;
  final String username;
  final bool guest;
  final bool isOperario;

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.guest,
    this.isOperario = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      email: json['email']?.toString(),
      username: json['username']?.toString() ?? 'Usuario',
      guest: json['guest'] == true,
      isOperario: json['isOperario'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'guest': guest,
        'isOperario': isOperario,
      };
}
