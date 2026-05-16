// Typed Dio service for `/auth/*` endpoints.
//
// 1:1 port of `gum_web/lib/auth/client.ts`. Every method maps to a
// route documented in `gum_api/src/modules/auth/auth.routes.ts`:
//
//   POST /auth/register            register
//   POST /auth/verify-otp          verifyRegisterOtp
//   POST /auth/resend-otp          resendRegisterOtp
//   POST /auth/login               login
//   POST /auth/refresh             refresh    (handled by AuthInterceptor)
//   POST /auth/logout              logout
//   POST /auth/forgot-password     forgotPassword
//   POST /auth/verify-reset-otp    verifyResetOtp
//   POST /auth/resend-reset-otp    resendResetOtp
//   POST /auth/reset-password      resetPassword

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/auth_tokens.dart';
import '../domain/auth_user.dart';
import '../domain/otp_models.dart';

/// Roles a user can self-assign right after OTP verification. Mirrors
/// the server's `SELF_ASSIGNABLE_ROLES` allow-list.
enum SelfAssignableRole { student, instructor }

extension SelfAssignableRoleX on SelfAssignableRole {
  String get wire => switch (this) {
        SelfAssignableRole.student   => 'student',
        SelfAssignableRole.instructor => 'instructor',
      };
}

class AuthApi {
  AuthApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  /// Most auth endpoints don't need a bearer (the server explicitly
  /// allows them) — flag via `extra: {'authRequired': false}`.
  Options get _noAuth => Options(extra: const {'authRequired': false});

  // ── Registration flow ──────────────────────────────────────────────

  Future<OtpInitiateResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
    SelfAssignableRole? role,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'first_name': firstName,
          'last_name':  lastName,
          'email':      email,
          'mobile':     mobile,
          'password':   password,
          if (role != null) 'role': role.wire,
        },
        options: _noAuth,
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return OtpInitiateResult.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  /// Returns either a [VerifyOtpProgress] (partial) or a
  /// [VerifyOtpComplete] (both channels verified → tokens + user).
  /// Callers should inspect with `isOtpComplete(raw)` and branch.
  Future<Map<String, dynamic>> verifyRegisterOtpRaw({
    required String pendingId,
    required String channel,    // 'email' | 'mobile'
    required String otp,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {'pending_id': pendingId, 'channel': channel, 'otp': otp},
        options: _noAuth,
      );
      return unwrapEnvelope<Map<String, dynamic>>(res);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<int> resendRegisterOtp({
    required String pendingId,
    required String channel,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/resend-otp',
        data: {'pending_id': pendingId, 'channel': channel},
        options: _noAuth,
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return (data['otp_expiry_seconds'] as num?)?.toInt() ?? 0;
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  // ── Login / Logout ─────────────────────────────────────────────────

  Future<VerifyOtpComplete> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'identifier': identifier, 'password': password},
        options: _noAuth,
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return VerifyOtpComplete.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> logout({String? refreshToken}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/logout',
        data: {'refresh_token': refreshToken},
      );
    } catch (_) {
      // Logout is best-effort — even if the server fails, we still wipe
      // the local session in the bloc.
    }
  }

  // ── Forgot password ────────────────────────────────────────────────

  Future<ResetInitiateResult> forgotPassword({
    required String email,
    required String mobile,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email, 'mobile': mobile},
        options: _noAuth,
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return ResetInitiateResult.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<ResetVerifyProgress> verifyResetOtp({
    required String resetPendingId,
    required String channel,
    required String otp,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/verify-reset-otp',
        data: {'reset_pending_id': resetPendingId, 'channel': channel, 'otp': otp},
        options: _noAuth,
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return ResetVerifyProgress.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<int> resendResetOtp({
    required String resetPendingId,
    required String channel,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/resend-reset-otp',
        data: {'reset_pending_id': resetPendingId, 'channel': channel},
        options: _noAuth,
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return (data['otp_expiry_seconds'] as num?)?.toInt() ?? 0;
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> resetPassword({
    required String resetPendingId,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {'reset_pending_id': resetPendingId, 'new_password': newPassword},
        options: _noAuth,
      );
      unwrapEnvelope<dynamic>(res);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  // ── Self-service role assignment (post-signup) ─────────────────────

  /// POST /users/me/roles — write the user's chosen role into
  /// `user_roles`. Retried up to 3 times with exponential backoff so
  /// flaky networks don't leave the user role-less.
  Future<Map<String, dynamic>> assignMyRole(SelfAssignableRole role) async {
    final delays = const [Duration.zero, Duration(milliseconds: 400), Duration(milliseconds: 1200)];
    Object? lastErr;
    for (var i = 0; i < delays.length; i++) {
      if (delays[i] > Duration.zero) await Future.delayed(delays[i]);
      try {
        final res = await _dio.post<Map<String, dynamic>>(
          '/users/me/roles',
          data: {'role': role.wire},
        );
        return unwrapEnvelope<Map<String, dynamic>>(res);
      } catch (e) {
        final err = ApiError.from(e);
        lastErr = err;
        // Don't retry on 4xx — only on network / 5xx.
        if (err.status >= 400 && err.status < 500) throw err;
      }
    }
    throw lastErr is ApiError ? lastErr : ApiError('Role assignment failed after retries', 0);
  }

  // ── (Conveniences re-exporting the inner shapes) ───────────────────

  AuthTokens tokensFrom(Map<String, dynamic> raw) => AuthTokens.fromJson(raw);
  AuthUser   userFrom  (Map<String, dynamic> raw) => AuthUser.fromJson((raw['user'] as Map<String, dynamic>?) ?? const {});

  // ═══════════════════════════════════════════════════════════════════
  // /profile/change-password — dual OTP flow
  //
  //   POST /profile/change-password/initiate    { old_password } → { pending_id, masked email/mobile, expiries }
  //   POST /profile/change-password/verify-otp  { pending_id, channel, otp } → progress + can_set_password
  //   POST /profile/change-password/confirm     { pending_id, new_password } → { logged_out: true }
  //   POST /profile/change-password/resend-otp  { pending_id, channel } → { otp_expiry_seconds }
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> changePasswordInitiate({required String oldPassword}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profile/change-password/initiate',
        data: {'old_password': oldPassword},
      );
      return unwrapEnvelope<Map<String, dynamic>>(res);
    } catch (e) { throw ApiError.from(e); }
  }

  /// Returns the server's verify-otp result. Keys:
  ///   email_verified, mobile_verified, both_verified, can_set_password
  Future<Map<String, dynamic>> changePasswordVerifyOtp({
    required String pendingId,
    required String channel,
    required String otp,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profile/change-password/verify-otp',
        data: {'pending_id': pendingId, 'channel': channel, 'otp': otp},
      );
      return unwrapEnvelope<Map<String, dynamic>>(res);
    } catch (e) { throw ApiError.from(e); }
  }

  /// Returns `{ logged_out: true }` on success — the server has
  /// invalidated the current session. Caller should wipe locally.
  Future<bool> changePasswordConfirm({
    required String pendingId,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profile/change-password/confirm',
        data: {'pending_id': pendingId, 'new_password': newPassword},
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return (data['logged_out'] ?? false) as bool;
    } catch (e) { throw ApiError.from(e); }
  }

  Future<int> changePasswordResendOtp({required String pendingId, required String channel}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profile/change-password/resend-otp',
        data: {'pending_id': pendingId, 'channel': channel},
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return (data['otp_expiry_seconds'] as num?)?.toInt() ?? 0;
    } catch (e) { throw ApiError.from(e); }
  }

  // ═══════════════════════════════════════════════════════════════════
  // /profile/update-email — single OTP sent to the NEW email
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> updateEmailInitiate({required String newEmail}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profile/update-email/initiate',
        data: {'new_email': newEmail},
      );
      return unwrapEnvelope<Map<String, dynamic>>(res);
    } catch (e) { throw ApiError.from(e); }
  }

  Future<Map<String, dynamic>> updateEmailVerifyOtp({
    required String pendingId,
    required String otp,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profile/update-email/verify-otp',
        data: {'pending_id': pendingId, 'otp': otp},
      );
      return unwrapEnvelope<Map<String, dynamic>>(res);
    } catch (e) { throw ApiError.from(e); }
  }

  Future<int> updateEmailResendOtp({required String pendingId}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profile/update-email/resend-otp',
        data: {'pending_id': pendingId},
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return (data['otp_expiry_seconds'] as num?)?.toInt() ?? 0;
    } catch (e) { throw ApiError.from(e); }
  }

  // ═══════════════════════════════════════════════════════════════════
  // /profile/update-mobile — single OTP sent to the NEW mobile
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> updateMobileInitiate({required String newMobile}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profile/update-mobile/initiate',
        data: {'new_mobile': newMobile},
      );
      return unwrapEnvelope<Map<String, dynamic>>(res);
    } catch (e) { throw ApiError.from(e); }
  }

  Future<Map<String, dynamic>> updateMobileVerifyOtp({
    required String pendingId,
    required String otp,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profile/update-mobile/verify-otp',
        data: {'pending_id': pendingId, 'otp': otp},
      );
      return unwrapEnvelope<Map<String, dynamic>>(res);
    } catch (e) { throw ApiError.from(e); }
  }

  Future<int> updateMobileResendOtp({required String pendingId}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/profile/update-mobile/resend-otp',
        data: {'pending_id': pendingId},
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return (data['otp_expiry_seconds'] as num?)?.toInt() ?? 0;
    } catch (e) { throw ApiError.from(e); }
  }
}
