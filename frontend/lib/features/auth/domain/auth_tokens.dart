import 'auth_user.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}

class AuthSession {
  final AuthUser user;
  final AuthTokens tokens;

  const AuthSession({required this.user, required this.tokens});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(json),
      );
}
