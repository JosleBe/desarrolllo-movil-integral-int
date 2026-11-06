/// Definición centralizada de rutas de navegación de la aplicación.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verificationPending = '/verification-pending';
  static const verify = '/verify';
  static const home = '/home';
  static const profile = '/profile';
  static const catalog = '/catalog';
  static const myListings = '/my-listings';
  static const listing = '/listing';
  static String listingDetail(String id) => '/listing/$id';

  static const public = {login, register, verificationPending, verify};
  static const guestOnly = {login, register};
}
