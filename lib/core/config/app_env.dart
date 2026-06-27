// App-wide environment config. The API base URL is what changes between
// local dev and production builds — everything else is constant.
//
// Default = the hosted production API (https://api.growupmore.com).
// Override at build time for local dev:
//   flutter run --dart-define=API_BASE_URL=http://localhost:5001/api/v1
//   (Android emulator → use http://10.0.2.2:5001/api/v1)

class AppEnv {
  AppEnv._();

  /// Compile-time override via `--dart-define=API_BASE_URL=...`.
  /// Empty string means "use the hosted default below".
  static const String _defineBase = String.fromEnvironment('API_BASE_URL');

  /// Hosted production API — the default for every build.
  static const String _hostedBase = 'https://api.growupmore.com/api/v1';

  /// Active API base URL — derived once on first access.
  static final String apiBaseUrl =
      _defineBase.isNotEmpty ? _defineBase : _hostedBase;
}
