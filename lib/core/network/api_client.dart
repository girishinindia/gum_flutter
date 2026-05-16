// Thin Dio wrapper. Single instance used by every feature's `*Api` class.
//
// Responsibilities:
//   • Set baseUrl from AppEnv
//   • Sensible timeouts (avoid hanging UI on flaky networks)
//   • Light log interceptor in debug only
//   • Default JSON content-type
//   • Auth: attach Bearer + transparent refresh via AuthInterceptor.
//     A second `refreshDio` is exposed for the interceptor to call
//     `/auth/refresh` without recursing through itself.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_interceptor.dart';
import '../config/app_env.dart';

class ApiClient {
  ApiClient._();

  /// Internal Dio used ONLY by the AuthInterceptor for the refresh call
  /// and for replaying the original request. Has no interceptors itself
  /// to avoid an infinite loop.
  static final Dio _refreshDio = _bareDio();

  /// The active interceptor — exposed so the AuthBloc can subscribe to
  /// `onSessionExpired` and react with a forced logout.
  static final AuthInterceptor authInterceptor =
      AuthInterceptor(refreshDio: _refreshDio);

  /// Single shared Dio instance for every API service in the app.
  static final Dio dio = _buildMain();

  static Dio _bareDio() {
    return Dio(
      BaseOptions(
        baseUrl: AppEnv.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout:    const Duration(seconds: 8),
        responseType:   ResponseType.json,
        headers: const {
          'Accept':       'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );
  }

  static Dio _buildMain() {
    final d = _bareDio();
    d.interceptors.add(authInterceptor);

    if (kDebugMode) {
      d.interceptors.add(LogInterceptor(
        request:      false,
        requestBody:  false,
        responseBody: false,
        error:        true,
        logPrint:     (o) => debugPrint(o.toString()),
      ));
    }
    return d;
  }
}
