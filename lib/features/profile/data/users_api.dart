// Typed Dio service for `/users/me` — identity + roles + max_role_level.
//
// Mirrors `getMe` / `updateMe` in `gum_web/lib/users/client.ts`. The
// PATCH body's `ALLOWED_FIELDS` on the server is:
//   first_name, last_name, display_name, locale, preferences, type

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/domain/auth_user.dart';

class UsersApi {
  UsersApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  /// GET /users/me — returns the user joined from `v_user_profile`,
  /// including roles, max_role_level, and display_name.
  Future<AuthUser> getMe() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me');
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return AuthUser.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  /// PATCH /users/me — update fields on the `users` row (not
  /// `user_profiles`). Use this for `display_name` / `locale` /
  /// `preferences` — sending these via `/user-profiles/me` would be
  /// silently dropped.
  Future<AuthUser> updateMe({
    String? firstName,
    String? lastName,
    String? displayName,
    String? locale,
    Map<String, dynamic>? preferences,
    String? type,
  }) async {
    final body = <String, dynamic>{
      if (firstName   != null) 'first_name':   firstName,
      if (lastName    != null) 'last_name':    lastName,
      if (displayName != null) 'display_name': displayName,
      if (locale      != null) 'locale':       locale,
      if (preferences != null) 'preferences':  preferences,
      if (type        != null) 'type':         type,
    };
    try {
      final res = await _dio.patch<Map<String, dynamic>>('/users/me', data: body);
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return AuthUser.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }
}
