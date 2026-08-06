// config/environment.dart
class Environment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  static String get current {
    return const String.fromEnvironment('ENV', defaultValue: development);
  }

  static bool get isDevelopment => current == development;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;

  static String get apiBaseUrl {
    switch (current) {
      case development:
        return 'http://localhost:8000/api';
      case staging:
        return 'https://staging-api.ktex.com/api';
      case production:
        return 'https://api.ktex.com/api';
      default:
        return 'http://localhost:8000/api';
    }
  }
}