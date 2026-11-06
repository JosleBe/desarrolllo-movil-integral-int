import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/profile_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/verify_email_page.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/catalog/presentation/listing_detail_page.dart';
import '../../features/home/presentation/home_shell.dart';
import 'app_routes.dart';

export 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    // Reevalúa las redirecciones cuando cambia el estado de sesión.
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);

      // Mientras se resuelve la sesión inicial, no redirigir.
      if (auth.isLoading && auth.user == null) return null;

      final loggedIn = auth.isAuthenticated;
      final location = state.matchedLocation;
      final onAuthFlow = AppRoutes.public.contains(location);

      // Sin sesión y fuera del flujo de auth: ir a login.
      if (!loggedIn && !onAuthFlow) return AppRoutes.login;

      // Con sesión y en login/registro: ir a home.
      if (loggedIn && AppRoutes.guestOnly.contains(location)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.verify,
        builder: (context, state) {
          final args = state.extra as VerifyArgs?;
          // Si se entra sin argumentos (p. ej. recarga web), vuelve a login.
          if (args == null) {
            return const LoginPage();
          }
          return VerifyEmailPage(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '${AppRoutes.listing}/:id',
        builder: (context, state) =>
            ListingDetailPage(listingId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Adapta el provider de sesión a un [Listenable] para que go_router
/// reevalúe `redirect` cada vez que cambia la autenticación.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}
