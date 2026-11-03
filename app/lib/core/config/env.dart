/// Configuración por ambiente, inyectada en compilación con `--dart-define`.
///
/// Ejemplo:
///   flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
///   flutter run --dart-define-from-file=env/dev.json
abstract final class Env {
  static const String name = String.fromEnvironment('ENV', defaultValue: 'dev');

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  /// Usa un backend simulado en memoria (sin servidor). Solo para desarrollo
  /// y demostraciones: nunca se activa en `prod`.
  static const bool _useFakeApiFlag = bool.fromEnvironment('USE_FAKE_API');

  static bool get isDev => name == 'dev';
  static bool get isProd => name == 'prod';
  static bool get useFakeApi => _useFakeApiFlag && !isProd;
}
