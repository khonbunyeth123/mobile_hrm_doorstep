// ============================================================
//  lib/config/app_config.dart
//  Central config — change IP/URL here only, never in services
// ============================================================

enum AppEnvironment { dev, prod }

class AppConfig {
  // Configure via --dart-define at build/run time.
  // Examples:
  // --dart-define=APP_ENV=prod
  // --dart-define=BASE_URL=https://api.example.com/api
  static const String _envRaw = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );
  static const String _baseOverride = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );

  // ─── Dev (local network) ────────────────────────────────
  static const String _devBase = String.fromEnvironment(
    'DEV_BASE_URL',
    defaultValue: 'http://192.168.0.104:8080/api',
  );

  // ─── Production (your live server) ──────────────────────
  static const String _prodBase = String.fromEnvironment(
    'PROD_BASE_URL',
    defaultValue: 'https://yourdomain.com/api',
  );

  static AppEnvironment get env =>
      _envRaw.toLowerCase() == 'prod'
          ? AppEnvironment.prod
          : AppEnvironment.dev;

  // ─── Active base URL (used by all services) ─────────────
  static String get baseUrl {
    final selected = _baseOverride.isNotEmpty
        ? _baseOverride
        : (env == AppEnvironment.dev ? _devBase : _prodBase);
    return _normalizeBaseUrl(selected);
  }

  // ─── Helpers ────────────────────────────────────────────
  static bool get isDev => env == AppEnvironment.dev;
  static bool get isProd => env == AppEnvironment.prod;

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
