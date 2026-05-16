// Shared error type thrown by every `*Api` service. Mirrors the
// `AuthApiError` / `UserApiError` classes in the web client.
//
// `status` lets the UI distinguish "network problem (0)" from
// "validation (400)" from "unauthorized (401)" etc. `details` carries
// the server's optional `details` payload when present (typically the
// Zod issue list — handy for field-level error mapping in Phase H).

import 'package:dio/dio.dart';

class ApiError implements Exception {
  ApiError(this.message, this.status, [this.details]) : isSilent = false;

  /// Phase 43.5 — companion ctor for errors the UI shouldn't render
  /// (today: 401s, which AuthBloc routes to /login on its own).
  ApiError._silent(this.message, this.status, this.details) : isSilent = true;

  final String  message;
  final int     status;
  final dynamic details;

  /// Phase 43.5 — true for errors that should NOT be rendered in the
  /// section's error banner. Today this is set for 401s because the
  /// AuthBloc is already handling the redirect to /login.
  final bool isSilent;

  /// Convenience predicate — screens generally use
  /// `if (!e.isSilent) setState(() => _formError = e.message);`
  /// so a single check covers both "expired session" and any future
  /// classes of errors we choose to swallow at the UI layer.
  bool get shouldShow => !isSilent;

  /// Build an [ApiError] from a Dio exception or any other thrown value.
  /// The web client unwraps `{ success, error, message, details }` —
  /// we mirror that here.
  factory ApiError.from(Object e) {
    if (e is ApiError) return e;

    if (e is DioException) {
      final res = e.response;
      final status = res?.statusCode ?? 0;
      final body = res?.data;
      if (body is Map<String, dynamic>) {
        final msg = (body['error'] ?? body['message']) as String?;
        // Phase 43.5 — 401 means the access token expired AND the refresh
        // queue's retry path failed (the interceptor either fell through
        // or has already dispatched AuthLoggedOut(expired:true)). At that
        // point the router is about to bounce the user to /login, so
        // there's no value in surfacing the raw server message ("Token
        // expired", "Invalid token") inside the section's error banner —
        // it just adds noise to the navigation. Force the friendly
        // default and mark the error as silent so screens can skip
        // rendering it entirely if they want.
        if (status == 401) {
          return ApiError._silent(_defaultMessage(status, e), status, body['details']);
        }
        return ApiError(
          msg ?? _defaultMessage(status, e),
          status,
          body['details'],
        );
      }
      if (status == 401) {
        return ApiError._silent(_defaultMessage(status, e), status, null);
      }
      return ApiError(_defaultMessage(status, e), status);
    }

    return ApiError(e.toString(), 0);
  }

  static String _defaultMessage(int status, DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Network error. Please check your connection.';
    }
    if (status == 0) return 'Network error. Please check your connection.';
    if (status == 401) return 'Session expired. Please sign in again.';
    if (status >= 500) return 'Server error ($status). Please try again.';
    return 'Request failed ($status).';
  }

  @override
  String toString() => 'ApiError($status): $message';
}

/// Unwrap the standard `{ success, data, error }` envelope.
/// Throws [ApiError] when `success` is false or HTTP status is non-2xx.
T unwrapEnvelope<T>(Response<dynamic> res) {
  final status = res.statusCode ?? 0;
  final body = res.data;

  if (body is! Map<String, dynamic>) {
    if (status >= 200 && status < 300) {
      // Some legacy endpoints return raw payloads.
      return body as T;
    }
    throw ApiError('Server error ($status)', status);
  }

  final ok = body['success'] == true;
  if (status < 200 || status >= 300 || !ok) {
    final msg = (body['error'] ?? body['message'] ?? 'Request failed ($status)') as String;
    // Phase 43.5 — 401 flows through here too because Dio's
    // validateStatus is `< 500`, so 4xx responses don't throw and the
    // AuthInterceptor's onError never fires. Mark as silent so the
    // section banner stays empty while AuthBloc handles the redirect.
    if (status == 401) {
      throw ApiError._silent('Session expired. Please sign in again.', status, body['details']);
    }
    throw ApiError(msg, status, body['details']);
  }

  final data = body['data'];
  if (data == null) return body as T; // some endpoints return at top level
  return data as T;
}
