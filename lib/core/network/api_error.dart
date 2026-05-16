// Shared error type thrown by every `*Api` service. Mirrors the
// `AuthApiError` / `UserApiError` classes in the web client.
//
// `status` lets the UI distinguish "network problem (0)" from
// "validation (400)" from "unauthorized (401)" etc. `details` carries
// the server's optional `details` payload when present (typically the
// Zod issue list — handy for field-level error mapping in Phase H).

import 'package:dio/dio.dart';

class ApiError implements Exception {
  ApiError(this.message, this.status, [this.details]);

  final String  message;
  final int     status;
  final dynamic details;

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
        return ApiError(
          msg ?? _defaultMessage(status, e),
          status,
          body['details'],
        );
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
    throw ApiError(msg, status, body['details']);
  }

  final data = body['data'];
  if (data == null) return body as T; // some endpoints return at top level
  return data as T;
}
