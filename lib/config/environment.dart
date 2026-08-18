import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Per-environment configuration for the KTEX app.
///
/// The backend API base URL is resolved in the following priority order:
///   1. `--dart-define=API_URL=...` (compile-time, ideal for release builds)
///   2. `API_URL` key in the `.env` file (loaded by flutter_dotenv at startup)
///   3. a sensible default per [current] environment.
class Environment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  /// Resolved at compile time via `--dart-define=ENV=...` (defaults to dev).
  static const String current = String.fromEnvironment(
    'ENV',
    defaultValue: development,
  );

  static bool get isDevelopment => current == development;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;

  /// Explicit override supplied via `--dart-define=API_URL=...`.
  static const String _fromEnvironment = String.fromEnvironment('API_URL');

  /// The backend API root URL (no trailing slash).
  static String get apiBaseUrl {
    final fromEnv = _fromEnvironment.trim();
    if (fromEnv.isNotEmpty) return fromEnv;

    if (dotenv.isInitialized) {
      final fromFile = dotenv.env['API_URL']?.trim() ?? '';
      if (fromFile.isNotEmpty) {
        // Allow `.env` to use bare host shorthand like "190.168.1.5:8000"
        // and normalize it to a full http:// URL.
        if (!fromFile.contains('://')) {
          return 'http://$fromFile';
        }
        return fromFile;
      }
    }

    switch (current) {
      case staging:
        return 'https://staging-api.ktex.com/api';
      case production:
        return 'https://api.ktex.com/api';
      default:
        // ✅ CHANGE THIS TO YOUR COMPUTER'S IP
        // For Android emulator: http://10.0.2.2:8000/api
        // For physical device: http://192.168.x.x:8000/api
        return 'http://192.168.110.44:8000/api';
    }
  }
}