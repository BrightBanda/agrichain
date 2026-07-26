import 'user.dart';

/// Mirrors `LoginResponse` — the token plus the user it belongs to.
class AuthSession {
  final String accessToken;
  final String tokenType;
  final User user;

  const AuthSession({
    required this.accessToken,
    required this.user,
    this.tokenType = 'bearer',
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: User.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
