// The repository is the single source of truth that bridges the UI
// (via AuthBloc) and the network (AuthApi + UsersApi). It also owns
// session persistence (SessionStorage) so the bloc doesn't have to
// know about secure storage details.
//
// Why a repository, not just an API service?
//   • Login / OTP-complete sequences touch multiple endpoints AND
//     write to disk — that orchestration lives here.
//   • Tests can swap a fake repository into the bloc without touching
//     Dio.

import 'dart:async';

import '../../../core/auth/session_storage.dart';
import '../../profile/data/users_api.dart';
import '../domain/auth_user.dart';
import '../domain/otp_models.dart';
import 'auth_api.dart';

// Re-export so callers only need to import the repository to get
// both the AuthRepository class and the SelfAssignableRole enum.
// `export` directives must appear in the directive section (above
// the first declaration) — see analyzer rule `directives_ordering`.
export 'auth_api.dart' show SelfAssignableRole;

class AuthRepository {
  AuthRepository({
    AuthApi?  authApi,
    UsersApi? usersApi,
  })  : _auth  = authApi  ?? AuthApi(),
        _users = usersApi ?? UsersApi();

  final AuthApi  _auth;
  final UsersApi _users;

  // Broadcast: emits whenever the session changes (login / logout /
  // refresh-fail). The AuthBloc subscribes to keep its state in sync.
  final _sessionCtl = StreamController<AuthUser?>.broadcast();
  Stream<AuthUser?> get sessionChanges => _sessionCtl.stream;

  // ── Bootstrap ──────────────────────────────────────────────────────

  /// Cold start. Hydrate the AuthUser blob from secure storage and, if a
  /// token is present, refresh it against the server. Returns the live
  /// user when authenticated, or `null` otherwise.
  Future<AuthUser?> bootstrap() async {
    final cached = await SessionStorage.getStoredUser();
    if (cached == null) return null;

    // Optimistically emit the cached user so the UI doesn't flash.
    _sessionCtl.add(cached);

    // Then refresh against the server. If /users/me 401s, the
    // AuthInterceptor will try a refresh; if THAT fails, the
    // `onSessionExpired` stream fires and we'll wipe the session.
    try {
      final live = await _users.getMe();
      await SessionStorage.setStoredUser(live);
      _sessionCtl.add(live);
      return live;
    } catch (_) {
      // Keep the cached blob — better stale than absent.
      return cached;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────

  Future<AuthUser> login({
    required String identifier,
    required String password,
  }) async {
    final complete = await _auth.login(identifier: identifier, password: password);
    await SessionStorage.persistSession(
      tokens: complete.tokens,
      user:   complete.user,
    );
    // Fetch the joined view to get roles + max_role_level.
    AuthUser hydrated = complete.user;
    try {
      hydrated = await _users.getMe();
      await SessionStorage.setStoredUser(hydrated);
    } catch (_) {/* fall through with the bare login response */}
    _sessionCtl.add(hydrated);
    return hydrated;
  }

  // ── Registration / OTP ─────────────────────────────────────────────

  Future<OtpInitiateResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
    SelfAssignableRole? role,
  }) =>
      _auth.register(
        firstName: firstName,
        lastName:  lastName,
        email:     email,
        mobile:    mobile,
        password:  password,
        role:      role,
      );

  /// Returns the hydrated [AuthUser] when both OTPs are verified and
  /// the session is now live. Returns `null` if only one channel
  /// verified so far — caller should ask for the other OTP.
  ///
  /// Returning the user directly (rather than `bool` + re-reading
  /// storage) lets the OTP screen dispatch `AuthLoggedIn(user)` with
  /// no extra round-trip — closes a race where the storage read could
  /// surface a stale or null blob.
  Future<AuthUser?> verifyRegisterOtp({
    required String pendingId,
    required String channel,
    required String otp,
    SelfAssignableRole? assignRoleAfter,
  }) async {
    final raw = await _auth.verifyRegisterOtpRaw(
      pendingId: pendingId,
      channel:   channel,
      otp:       otp,
    );

    if (isOtpComplete(raw)) {
      final complete = VerifyOtpComplete.fromJson(raw);
      await SessionStorage.persistSession(
        tokens: complete.tokens,
        user:   complete.user,
      );

      // Post-signup role assignment — best effort, retries inside the API.
      if (assignRoleAfter != null) {
        try { await _auth.assignMyRole(assignRoleAfter); } catch (_) {}
      }

      // Re-fetch to surface roles + max_role_level.
      AuthUser hydrated = complete.user;
      try {
        hydrated = await _users.getMe();
        await SessionStorage.setStoredUser(hydrated);
      } catch (_) {/* fall back to the OTP-complete blob */}
      _sessionCtl.add(hydrated);
      return hydrated;
    }
    return null;
  }

  Future<int> resendRegisterOtp({required String pendingId, required String channel}) =>
      _auth.resendRegisterOtp(pendingId: pendingId, channel: channel);

  // ── Forgot password ────────────────────────────────────────────────

  Future<ResetInitiateResult> forgotPassword({required String email, required String mobile}) =>
      _auth.forgotPassword(email: email, mobile: mobile);

  Future<ResetVerifyProgress> verifyResetOtp({
    required String resetPendingId,
    required String channel,
    required String otp,
  }) =>
      _auth.verifyResetOtp(resetPendingId: resetPendingId, channel: channel, otp: otp);

  Future<int> resendResetOtp({required String resetPendingId, required String channel}) =>
      _auth.resendResetOtp(resetPendingId: resetPendingId, channel: channel);

  Future<void> resetPassword({required String resetPendingId, required String newPassword}) =>
      _auth.resetPassword(resetPendingId: resetPendingId, newPassword: newPassword);

  // ── Logout ─────────────────────────────────────────────────────────

  Future<void> logout() async {
    final refresh = await SessionStorage.getRefreshToken();
    try { await _auth.logout(refreshToken: refresh); } catch (_) {}
    await SessionStorage.clearSession();
    _sessionCtl.add(null);
  }

  /// Fired by the AuthInterceptor when refresh fails — wipe + notify.
  Future<void> handleSessionExpired() async {
    await SessionStorage.clearSession();
    _sessionCtl.add(null);
  }

  // ── Profile mutation (display_name etc.) ───────────────────────────

  /// PATCH /users/me — keeps the cached AuthUser in sync.
  Future<AuthUser> updateMe({
    String? firstName,
    String? lastName,
    String? displayName,
    String? locale,
    Map<String, dynamic>? preferences,
  }) async {
    final updated = await _users.updateMe(
      firstName:   firstName,
      lastName:    lastName,
      displayName: displayName,
      locale:      locale,
      preferences: preferences,
    );
    await SessionStorage.setStoredUser(updated);
    _sessionCtl.add(updated);
    return updated;
  }

  Future<void> dispose() => _sessionCtl.close();

  /// Read access for the bloc's hydration path. Returns null when no
  /// blob is cached (cold install / post-logout).
  Future<AuthUser?> cachedUser() => SessionStorage.getStoredUser();

  /// Read access for the router's redirect guard.
  Future<bool> hasSession() => SessionStorage.hasSession();

  // ── Security operations (Phase G) ──────────────────────────────────
  //
  // The three flows below run while the user is authenticated. On
  // success the server invalidates the session (`logged_out: true`),
  // so the caller is expected to follow up with `wipeSessionLocally()`
  // and route to /login.

  Future<Map<String, dynamic>> changePasswordInitiate({required String oldPassword}) =>
      _auth.changePasswordInitiate(oldPassword: oldPassword);

  Future<Map<String, dynamic>> changePasswordVerifyOtp({
    required String pendingId,
    required String channel,
    required String otp,
  }) =>
      _auth.changePasswordVerifyOtp(pendingId: pendingId, channel: channel, otp: otp);

  Future<bool> changePasswordConfirm({required String pendingId, required String newPassword}) =>
      _auth.changePasswordConfirm(pendingId: pendingId, newPassword: newPassword);

  Future<int> changePasswordResendOtp({required String pendingId, required String channel}) =>
      _auth.changePasswordResendOtp(pendingId: pendingId, channel: channel);

  Future<Map<String, dynamic>> updateEmailInitiate({required String newEmail}) =>
      _auth.updateEmailInitiate(newEmail: newEmail);

  Future<Map<String, dynamic>> updateEmailVerifyOtp({required String pendingId, required String otp}) =>
      _auth.updateEmailVerifyOtp(pendingId: pendingId, otp: otp);

  Future<int> updateEmailResendOtp({required String pendingId}) =>
      _auth.updateEmailResendOtp(pendingId: pendingId);

  Future<Map<String, dynamic>> updateMobileInitiate({required String newMobile}) =>
      _auth.updateMobileInitiate(newMobile: newMobile);

  Future<Map<String, dynamic>> updateMobileVerifyOtp({required String pendingId, required String otp}) =>
      _auth.updateMobileVerifyOtp(pendingId: pendingId, otp: otp);

  Future<int> updateMobileResendOtp({required String pendingId}) =>
      _auth.updateMobileResendOtp(pendingId: pendingId);

  /// After a `logged_out: true` response from one of the three Security
  /// flows, the caller invokes this to wipe storage and notify the
  /// AuthBloc — the router will then redirect to /login.
  Future<void> wipeSessionLocally() async {
    await SessionStorage.clearSession();
    _sessionCtl.add(null);
  }
}
