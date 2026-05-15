// App-wide environment config. The API base URL is what changes between
// local dev and production builds — everything else is constant.
//
// Override at build time:
//   flutter run --dart-define=API_BASE_URL=https://api.growupmore.com/api/v1
//
// The default below targets the local Express dev server on port 5001.
// On Android emulators, 10.0.2.2 maps to the host's localhost.

import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppEnv {
  AppEnv._();

  /// Compile-time override via `--dart-define=API_BASE_URL=...`.
  /// Empty string means "use the platform default below".
  static const String _defineBase = String.fromEnvironment('API_BASE_URL');

  /// Active API base URL — derived once on first access.
  static final String apiBaseUrl = _defineBase.isNotEmpty
      ? _defineBase
      : _platformDefault();

  static String _platformDefault() {
    // Web / desktop debug: assume host machine
    if (kIsWeb) return 'http://localhost:5001/api/v1';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5001/api/v1';
      if (Platform.isIOS)     return 'http://localhost:5001/api/v1';
    } catch (_) {/* fall through */}
    return 'http://localhost:5001/api/v1';
  }
}
