/// Build-time environment, populated via `--dart-define`.
///
/// API base URL (no trailing slash):
/// - Android emulator: `http://10.0.2.2:3000` (maps to host machine localhost)
/// - Physical device: your PC's LAN IP, e.g. `http://192.168.1.42:3000`
///   (`localhost` on the phone means the phone itself, not your computer)
/// - iOS simulator: `http://localhost:3000`
///
/// Example (physical Android phone on same Wi‑Fi):
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.42:3000
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// dev | staging | prod
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static bool get isProd => flavor == 'prod';
}
