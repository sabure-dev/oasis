class User {
  final int id;
  final String username;
  final String email;
  final bool isVerified;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      isVerified: json['is_verified'] ?? false,
    );
  }
}
