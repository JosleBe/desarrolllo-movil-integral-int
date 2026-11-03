abstract final class AppRoutes {
  static const splash = '/cargando';
  static const login = '/login';
  static const register = '/registro';
  static const verificationPending = '/registro/pendiente';
  static const verify = '/verificar';
  static const home = '/';

  /// Rutas accesibles sin sesión.
  static const public = {login, register, verificationPending, verify};

  /// Rutas de acceso que no tienen sentido con sesión iniciada.
  static const guestOnly = {login, register, verificationPending};

  static String loginWith({String? email}) => Uri(
    path: login,
    queryParameters: email == null ? null : {'email': email},
  ).toString();

  static String pendingFor(String email) => Uri(
    path: verificationPending,
    queryParameters: {'email': email},
  ).toString();

  static String verifyWith(String token) =>
      Uri(path: verify, queryParameters: {'token': token}).toString();
}
