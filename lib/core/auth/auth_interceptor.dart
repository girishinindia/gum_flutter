// Dio interceptor that handles the entire auth-token lifecycle:
//
//   1. Outbound — attach `Authorization: Bearer <access_token>` to every
//      request that doesn't already carry one.
//
//   2. 401 inbound — try refreshing the access token with the stored
//      refresh token. While the refresh call is in flight, queue any
//      subsequent 401s so we make exactly ONE refresh call no matter how
//      many parallel requests fail at once.
//
//   3. Post-refresh — replay the original request once with the new
//      access token. If refresh itself fails (invalid / expired refresh
//      token), wipe the session and surface a sentinel error so the
//      AuthBloc can flip to `unauthenticated` and the router can bounce
//      the user to /login.
//
// This is the Flutter counterpart of the web side, which doesn't need
// a refresh queue because fetch() and Next.js handle that differently.

import 'dart:async';

import 'package:dio/dio.dart';

import 'session_storage.dart';
import '../../features/auth/domain/auth_tokens.dart';

/// Sentinel error fired when refresh fails. The AuthBloc listens for
/// this via a `Stream<AuthInterceptorEvent>` exposed by the interceptor.
class SessionExpiredError implements Exception {
  const SessionExpiredError();
  @override
  String toString() => 'SessionExpiredError: refresh token is invalid';
}

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required Dio refreshDio}) : _refreshDio = refreshDio;

  /// Separate Dio used to call `/auth/refresh` so the interceptor doesn't
  /// recurse into itself when refreshing.
  final Dio _refreshDio;

  /// Broadcast stream the AuthBloc subscribes to so it can react to
  /// "refresh failed → log the user out". Typed as `Object?` rather
  /// than `void` so `add(null)` doesn't trip `invalid_use_of_void`.
  final _sessionExpiredCtl = StreamController<Object?>.broadcast();
  Stream<Object?> get onSessionExpired => _sessionExpiredCtl.stream;

  /// In-flight refresh future. While non-null, additional 401s wait on it
  /// instead of triggering parallel refreshes.
  Future<String?>? _inflightRefresh;

  // ── Outbound ────────────────────────────────────────────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Caller can opt out of auth by setting `extra['authRequired'] = false`.
    final required = (options.extra['authRequired'] as bool?) ?? true;
    if (!required) return handler.next(options);

    final tok = await SessionStorage.getAccessToken();
    if (tok != null && tok.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $tok';
    }
    return handler.next(options);
  }

  // ── Inbound — 401 handling ─────────────────────────────────────────
  //
  // Phase 43.5 — ApiClient configures Dio with `validateStatus: s < 500`
  // so 401 responses come through `onResponse`, not `onError`. We have
  // to refresh from BOTH hooks: onResponse for the common case, onError
  // for the rare path where the server (or a 5xx adjacent) actually
  // throws.

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final status = response.statusCode;
    final reqOpts = response.requestOptions;
    final isRefreshCall = reqOpts.path.endsWith('/auth/refresh');

    if (status == 401 && !isRefreshCall && !_alreadyRetried(reqOpts)) {
      final retried = await _tryRefreshAndReplay(reqOpts);
      if (retried != null) return handler.resolve(retried);
      // Refresh failed — fall through with the original 401 response so
      // unwrapEnvelope throws a silent ApiError (the AuthBloc has
      // already been signalled to log out).
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final res = err.response;
    final status = res?.statusCode;
    final reqOpts = err.requestOptions;

    // Bypass for the refresh endpoint itself.
    final isRefreshCall = reqOpts.path.endsWith('/auth/refresh');

    if (status == 401 && !isRefreshCall && !_alreadyRetried(reqOpts)) {
      final retried = await _tryRefreshAndReplay(reqOpts);
      if (retried != null) return handler.resolve(retried);
      return handler.next(err);
    }

    return handler.next(err);
  }

  /// Phase 43.5 — shared body for the two refresh-replay hooks. Returns
  /// the replayed Response on success, null on failure (and signals
  /// AuthBloc to log the user out as a side effect).
  Future<Response<dynamic>?> _tryRefreshAndReplay(RequestOptions reqOpts) async {
    final newAccess = await _refreshOnce();
    if (newAccess == null) {
      await SessionStorage.clearSession();
      _sessionExpiredCtl.add(null);
      return null;
    }
    _markRetried(reqOpts);
    reqOpts.headers['Authorization'] = 'Bearer $newAccess';
    try {
      return await _refreshDio.fetch<dynamic>(reqOpts);
    } catch (_) {
      return null;
    }
  }

  // ── Refresh plumbing ────────────────────────────────────────────────

  static const _retriedFlag = '__authRetried';

  bool _alreadyRetried(RequestOptions r) => r.extra[_retriedFlag] == true;
  void _markRetried(RequestOptions r) { r.extra[_retriedFlag] = true; }

  /// Returns the new access token on success, `null` on failure. Coalesces
  /// concurrent callers onto a single in-flight refresh future.
  Future<String?> _refreshOnce() {
    final existing = _inflightRefresh;
    if (existing != null) return existing;

    final fut = _doRefresh().whenComplete(() {
      _inflightRefresh = null;
    });
    _inflightRefresh = fut;
    return fut;
  }

  Future<String?> _doRefresh() async {
    final refresh = await SessionStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;

    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
        options: Options(extra: {'authRequired': false}),
      );

      final body = res.data ?? const {};
      final ok = body['success'] == true;
      final data = body['data'] as Map<String, dynamic>?;
      if (!ok || data == null) return null;

      final tokens = AuthTokens.fromJson(data);
      await SessionStorage.setTokens(tokens);
      return tokens.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _sessionExpiredCtl.close();
  }
}
