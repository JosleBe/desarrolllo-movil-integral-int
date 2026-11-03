import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/core/router/app_router.dart';
import 'package:sruu/features/auth/domain/auth_models.dart';
import 'package:sruu/features/auth/presentation/session_controller.dart';

void main() {
  final signedIn = SignedIn(
    user: const AuthUser(
      id: '1',
      email: 'a@utez.edu.mx',
      fullName: 'Ana',
      status: AccountStatus.verified,
      role: UserRole.base,
    ),
    expiresAt: DateTime(2100),
  );

  test('sin sesión, las rutas privadas llevan al login', () {
    expect(authRedirect(const SignedOut(), Uri.parse('/')), AppRoutes.login);
  });

  test('sin sesión, las rutas de acceso y verificación están abiertas', () {
    for (final path in AppRoutes.public) {
      expect(
        authRedirect(const SignedOut(), Uri.parse(path)),
        isNull,
        reason: path,
      );
    }
  });

  test('el enlace de verificación funciona mientras se restaura la sesión', () {
    expect(
      authRedirect(const SessionRestoring(), Uri.parse('/verificar?token=x')),
      isNull,
    );
  });

  test('con sesión, login y registro llevan al inicio', () {
    expect(authRedirect(signedIn, Uri.parse(AppRoutes.login)), AppRoutes.home);
    expect(
      authRedirect(signedIn, Uri.parse(AppRoutes.register)),
      AppRoutes.home,
    );
    expect(authRedirect(signedIn, Uri.parse('/')), isNull);
  });

  test('no redirige a destinos externos', () {
    expect(
      authRedirect(signedIn, Uri.parse('/cargando?from=//evil.com')),
      AppRoutes.home,
    );
  });
}
