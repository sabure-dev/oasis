class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'] ?? 'bearer',
    );
  }
}

class UserRegisterRequest {
  final String username;
  final String email;
  final String password;

  UserRegisterRequest(
      {required this.username, required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
      };
}
