class AppUser {
  final int? id;
  final String? email;
  final String username;
  final bool guest;

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.guest,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      email: json['email']?.toString(),
      username: json['username']?.toString() ?? 'Usuario',
      guest: json['guest'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'guest': guest,
      };
}
