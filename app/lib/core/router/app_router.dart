import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/auth/presentation/verification_pending_page.dart';
import '../../features/auth/presentation/verify_email_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../widgets/sentence.dart';
import 'app_routes.dart';

export 'app_routes.dart';

/// Decide a dónde ir según la sesión. Se exporta para probarla aislada.
String? authRedirect(SessionState session, Uri location) {
  final path = location.path;
  return switch (session) {
    SessionRestoring() =>
      path == AppRoutes.splash || path == AppRoutes.verify
          ? null
          : _withFrom(AppRoutes.splash, location),
    SignedOut() => AppRoutes.public.contains(path) ? null : AppRoutes.login,
    SignedIn() =>
      path == AppRoutes.splash
          ? _safeFrom(location) ?? AppRoutes.home
          : AppRoutes.guestOnly.contains(path)
          ? AppRoutes.home
          : null,
  };
}

String _withFrom(String target, Uri location) =>
    location.path == AppRoutes.home || AppRoutes.public.contains(location.path)
    ? target
    : Uri(
        path: target,
        queryParameters: {'from': location.toString()},
      ).toString();

/// Solo rutas internas privadas, para evitar redirecciones abiertas.
String? _safeFrom(Uri location) {
  final from = location.queryParameters['from'];
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  return from;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(ref.read(sessionControllerProvider), state.uri),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _page(state, const _SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _page(
          state,
          LoginPage(initialEmail: state.uri.queryParameters['email']),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _page(state, const RegisterPage()),
      ),
      GoRoute(
        path: AppRoutes.verificationPending,
        pageBuilder: (context, state) => _page(
          state,
          VerificationPendingPage(email: state.uri.queryParameters['email']),
        ),
      ),
      GoRoute(
        path: AppRoutes.verify,
        pageBuilder: (context, state) => _page(
          state,
          VerifyEmailPage(token: state.uri.queryParameters['token']),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _page(state, const HomePage()),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Sin animación de ruta: la transición es el cambio de color de fondo.
NoTransitionPage<void> _page(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) => const SentenceScaffold(
    scene: Scene.mint,
    busy: true,
    children: [Say('Un momento…')],
  );
}
