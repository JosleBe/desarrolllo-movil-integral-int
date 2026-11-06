/// Definición centralizada de rutas de navegación de la aplicación.
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const verify = '/verify';
  static const home = '/home';
  static const profile = '/profile';
  static const listing = '/listing';

  /// Ruta de detalle de una publicación por id.
  static String listingDetail(String id) => '$listing/$id';

  /// Rutas accesibles sin sesión iniciada.
  static const public = {login, register, verify};

  /// Rutas que solo tienen sentido sin sesión iniciada.
  static const guestOnly = {login, register};
}
