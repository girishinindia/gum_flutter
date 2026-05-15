// Thin Dio wrapper. Single instance used by every feature's `*Api` class.
//
// Responsibilities:
//   • Set baseUrl from AppEnv
//   • Sensible timeouts (avoid hanging UI on flaky networks)
//   • Light log interceptor in debug only
//   • Default JSON content-type
//
// Auth interceptors are NOT added here — public endpoints don't need
// them. Add later inside this class when the auth layer lands.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_env.dart';

class ApiClient {
  ApiClient._();

  /// Single shared Dio instance.
  static final Dio dio = _build();

  static Dio _build() {
    final d = Dio(
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
        // Don't throw on 4xx — let callers decide. Avoids try/catch
        // around every harmless 404.
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (kDebugMode) {
      d.interceptors.add(LogInterceptor(
        request:     false,
        requestBody: false,
        responseBody: false,
        error: true,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }

    return d;
  }
}
