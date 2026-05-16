// Bearer access + refresh token pair. Mirrors `AuthTokens` in
// `gum_web/lib/auth/session.ts` — same wire keys.

import 'package:equatable/equatable.dart';

class AuthTokens extends Equatable {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> j) => AuthTokens(
        accessToken:  (j['access_token']  ?? '') as String,
        refreshToken: (j['refresh_token'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'access_token':  accessToken,
        'refresh_token': refreshToken,
      };

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
