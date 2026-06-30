

enum AppEnvironment { dev, prod }

class AppConfig {
  // ✅ Switch between dev and prod here
  static const AppEnvironment env = AppEnvironment.dev;

  // ─── Dev (local network) ────────────────────────────────
  static const String _devIp = '172.167.50.236';
  static const String _devPort = '8080';
  static const String _devBase = 'http://$_devIp:$_devPort/api';

  // ─── Production (your live server) ──────────────────────
  static const String _prodBase = 'https://yourdomain.com/api';

  // ─── Active base URL (used by all services) ─────────────
  static String get baseUrl => env == AppEnvironment.dev ? _devBase : _prodBase;

  // ─── Helpers ────────────────────────────────────────────
  static bool get isDev => env == AppEnvironment.dev;
  static bool get isProd => env == AppEnvironment.prod;
}
