import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/core/router/app_router.dart';
import 'package:sruu/core/storage/token_storage.dart';
import 'package:sruu/features/auth/data/fake_auth_repository.dart';
import 'package:sruu/features/auth/domain/auth_validators.dart';
import 'package:sruu/features/auth/presentation/session_controller.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('sin sesión arranca en la frase para entrar', (tester) async {
    await pumpApp(tester);
    expect(find.text('Soy'), findsOneWidget);
    expect(find.text('y mi clave es'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  Future<void> fillRegister(
    WidgetTester tester, {
    required String matricula,
  }) async {
    await tester.tap(find.text('Soy nuevo'));
    await tester.pumpAndSettle();
    await tester.enterText(field('register-name'), 'Leo Martínez');
    await tester.enterText(field('register-matricula'), matricula);
    await tester.enterText(field('register-password'), 'Segura123');
    await tester.enterText(field('register-confirm'), 'Segura123');
    await tester.tap(find.text('Crear mi cuenta'));
    await tester.pumpAndSettle();
  }

  group('HU-01', () {
    testWidgets('el dominio @utez.edu.mx es parte fija de la frase', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Soy nuevo'));
      await tester.pumpAndSettle();
      expect(find.text('@utez.edu.mx'), findsOneWidget);
    });

    testWidgets('rechaza un correo de otro dominio con un mensaje claro', (
      tester,
    ) async {
      final repo = fakeRepo();
      await pumpApp(tester, repo: repo);
      await fillRegister(tester, matricula: 'alguien@gmail.com');

      expect(find.text(AuthValidators.domainMessage), findsOneWidget);
      expect(find.text('Crear mi cuenta'), findsOneWidget);
      expect(repo.lastEmailTo('alguien@gmail.com'), isNull);
    });

    testWidgets('un registro válido queda pendiente de verificación', (
      tester,
    ) async {
      final repo = fakeRepo();
      await pumpApp(tester, repo: repo);
      await fillRegister(tester, matricula: '20223tn067');

      expect(find.textContaining('pendiente de verificación'), findsOneWidget);
      expect(find.textContaining('Te mandamos un enlace a'), findsOneWidget);
      expect(repo.lastEmailTo('20223tn067@utez.edu.mx'), isNotNull);
    });
  });

  group('HU-02', () {
    Future<void> registerLeo(FakeAuthRepository repo) => repo.register(
      fullName: 'Leo Martínez',
      email: 'leo@utez.edu.mx',
      password: 'Segura123',
    );

    testWidgets('un enlace vigente activa la cuenta como Usuario Base', (
      tester,
    ) async {
      final repo = fakeRepo();
      await registerLeo(repo);
      final container = await pumpApp(tester, repo: repo);
      final token = repo.lastEmailTo('leo@utez.edu.mx')!.token;

      container.read(routerProvider).go('/verificar?token=$token');
      await tester.pumpAndSettle();

      expect(find.textContaining('Listo, '), findsOneWidget);
      expect(find.textContaining('verificada'), findsOneWidget);
      expect(find.textContaining('Usuario Base'), findsOneWidget);
    });

    testWidgets('un enlace vencido ofrece reenviar uno nuevo', (tester) async {
      final repo = fakeRepo();
      await registerLeo(repo);
      final token = repo.lastEmailTo('leo@utez.edu.mx')!.token;
      repo.debugExpireVerificationTokens('leo@utez.edu.mx');
      final container = await pumpApp(tester, repo: repo);

      container.read(routerProvider).go('/verificar?token=$token');
      await tester.pumpAndSettle();

      expect(find.text('Ese enlace ya venció.'), findsOneWidget);
      await tester.tap(find.text('Mándame uno nuevo'));
      await tester.pumpAndSettle();
      expect(repo.lastEmailTo('leo@utez.edu.mx')!.token, isNot(token));
      expect(
        find.textContaining('va en camino un enlace nuevo'),
        findsOneWidget,
      );
    });

    testWidgets('un enlace ya usado ofrece reenviar uno nuevo', (tester) async {
      final repo = fakeRepo();
      await registerLeo(repo);
      final token = repo.lastEmailTo('leo@utez.edu.mx')!.token;
      await repo.verifyEmail(token);
      final container = await pumpApp(tester, repo: repo);

      container.read(routerProvider).go('/verificar?token=$token');
      await tester.pumpAndSettle();

      expect(find.text('Ese enlace ya se usó.'), findsOneWidget);
      expect(find.text('Mándame uno nuevo'), findsOneWidget);
    });
  });

  group('HU-03', () {
    Future<void> login(WidgetTester tester, String user, String pass) async {
      await tester.enterText(field('login-matricula'), user);
      await tester.enterText(field('login-password'), pass);
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
    }

    testWidgets('credenciales incorrectas muestran un error genérico', (
      tester,
    ) async {
      await pumpApp(tester);
      const generic = 'Ese correo o esa clave no coinciden.';

      await login(tester, 'demo', 'Incorrecta1');
      expect(find.textContaining(generic), findsOneWidget);

      await login(tester, 'noexiste', 'Demo1234');
      expect(find.textContaining(generic), findsOneWidget);
    });

    testWidgets('iniciar y cerrar sesión', (tester) async {
      final storage = InMemoryTokenStorage();
      final container = await pumpApp(tester, storage: storage);

      await login(tester, 'demo', 'Demo1234');
      expect(find.textContaining('Hola, '), findsOneWidget);
      expect(await storage.read(), isNotNull);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(container.read(sessionControllerProvider), isA<SignedOut>());
      expect(await storage.read(), isNull);
      expect(find.text('Entrar'), findsOneWidget);
    });
  });
}
