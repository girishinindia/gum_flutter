// Secure on-device persistence for the authenticated user.
//
// Web equivalent: `gum_web/lib/auth/session.ts` (which uses localStorage).
// In Flutter, tokens go through `flutter_secure_storage` instead — that's
// Keychain on iOS and EncryptedSharedPreferences on Android. The user
// blob is cached too so we can hydrate the AuthBloc synchronously on
// cold start and avoid an empty splash flicker.
//
// Keys mirror the web side intentionally so a future "log in once,
// roam everywhere" SSO story stays simple.

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/auth_user.dart';
import '../../features/auth/domain/auth_tokens.dart';

class SessionStorage {
  SessionStorage._();

  static const _kAccess  = 'gum.auth.access';
  static const _kRefresh = 'gum.auth.refresh';
  static const _kUser    = 'gum.auth.user';

  /// Android: EncryptedSharedPreferences with AES-256.
  /// iOS:     Keychain in the user's default accessible group.
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Tokens ──────────────────────────────────────────────────────────

  static Future<String?> getAccessToken()  => _secure.read(key: _kAccess);
  static Future<String?> getRefreshToken() => _secure.read(key: _kRefresh);

  static Future<void> setTokens(AuthTokens t) async {
    await Future.wait([
      _secure.write(key: _kAccess,  value: t.accessToken),
      _secure.write(key: _kRefresh, value: t.refreshToken),
    ]);
  }

  static Future<void> clearTokens() async {
    await Future.wait([
      _secure.delete(key: _kAccess),
      _secure.delete(key: _kRefresh),
    ]);
  }

  // ── User blob ───────────────────────────────────────────────────────

  static Future<AuthUser?> getStoredUser() async {
    final raw = await _secure.read(key: _kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt blob — treat as no session, force a re-fetch on next login.
      await _secure.delete(key: _kUser);
      return null;
    }
  }

  static Future<void> setStoredUser(AuthUser u) async {
    await _secure.write(key: _kUser, value: jsonEncode(u.toJson()));
  }

  static Future<void> clearStoredUser() => _secure.delete(key: _kUser);

  // ── Combined ────────────────────────────────────────────────────────

  /// Persist the result of a successful login / OTP-complete flow.
  static Future<void> persistSession({
    required AuthTokens tokens,
    required AuthUser user,
  }) async {
    await Future.wait([
      setTokens(tokens),
      setStoredUser(user),
    ]);
  }

  static Future<void> clearSession() async {
    await Future.wait([
      clearTokens(),
      clearStoredUser(),
    ]);
  }

  /// Cheap synchronous-ish check used by the router redirect.
  /// Falls back to `false` on any read error.
  static Future<bool> hasSession() async {
    try {
      final t = await getAccessToken();
      return t != null && t.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
