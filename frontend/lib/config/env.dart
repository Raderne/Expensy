/// Build-time environment, populated via `--dart-define`.
///
/// Example:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
///               --dart-define=FLAVOR=dev
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
