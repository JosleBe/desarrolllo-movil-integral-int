import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/auth/data/fake_auth_repository.dart';
import 'package:sruu/features/auth/domain/auth_models.dart';

import '../../helpers/test_app.dart';

void main() {
  late DateTime now;
  late FakeAuthRepository repo;

  setUp(() {
    now = DateTime.utc(2026, 11, 3, 10);
    repo = fakeRepo(clock: () => now);
  });

  Future<AuthUser> register([String email = 'nuevo@utez.edu.mx']) => repo
      .register(fullName: 'Nuevo Alumno', email: email, password: 'Segura123');

  String tokenFor(String email) => repo.lastEmailTo(email)!.token;

  group('HU-01 registro', () {
    test('rechaza dominios distintos a @utez.edu.mx', () {
      expect(
        register('alguien@gmail.com'),
        throwsA(isA<InstitutionalEmailRequired>()),
      );
    });

    test('crea la cuenta pendiente de verificación y sin rol', () async {
      final user = await register();
      expect(user.status, AccountStatus.pendingVerification);
      expect(user.role, UserRole.none);
    });

    test('el correo es único (sin distinguir mayúsculas)', () async {
      await register();
      expect(
        register('NUEVO@utez.edu.mx'),
        throwsA(isA<EmailAlreadyRegistered>()),
      );
    });
  });

  group('HU-02 verificación', () {
    test('al registrarse se envía un token al correo', () async {
      await register();
      expect(repo.lastEmailTo('nuevo@utez.edu.mx'), isNotNull);
    });

    test('token vigente → verificada con rol Usuario Base', () async {
      await register();
      final user = await repo.verifyEmail(tokenFor('nuevo@utez.edu.mx'));
      expect(user.status, AccountStatus.verified);
      expect(user.role, UserRole.base);
    });

    test(
      'token ya usado → TokenAlreadyUsed con el correo para reenviar',
      () async {
        await register();
        final token = tokenFor('nuevo@utez.edu.mx');
        await repo.verifyEmail(token);
        await expectLater(
          repo.verifyEmail(token),
          throwsA(
            isA<VerificationTokenAlreadyUsed>().having(
              (f) => f.email,
              'email',
              'nuevo@utez.edu.mx',
            ),
          ),
        );
      },
    );

    test('token vencido (24 h) → TokenExpired con el correo', () async {
      await register();
      final token = tokenFor('nuevo@utez.edu.mx');
      now = now.add(const Duration(hours: 24));
      await expectLater(
        repo.verifyEmail(token),
        throwsA(
          isA<VerificationTokenExpired>().having(
            (f) => f.email,
            'email',
            'nuevo@utez.edu.mx',
          ),
        ),
      );
    });

    test('reenviar invalida el token anterior y el nuevo funciona', () async {
      await register();
      final old = tokenFor('nuevo@utez.edu.mx');
      await repo.resendVerification('nuevo@utez.edu.mx');
      final fresh = tokenFor('nuevo@utez.edu.mx');
      expect(fresh, isNot(old));
      await expectLater(
        repo.verifyEmail(old),
        throwsA(isA<VerificationTokenAlreadyUsed>()),
      );
      expect((await repo.verifyEmail(fresh)).isVerified, isTrue);
    });

    test('reenviar a un correo desconocido no revela que no existe', () async {
      await expectLater(
        repo.resendVerification('nadie@utez.edu.mx'),
        completes,
      );
    });

    test('el reenvío respeta un tiempo de espera', () async {
      final strict = FakeAuthRepository(
        latency: Duration.zero,
        clock: () => now,
      );
      await strict.register(
        fullName: 'Ana',
        email: 'ana@utez.edu.mx',
        password: 'Segura123',
      );
      expect(
        strict.resendVerification('ana@utez.edu.mx'),
        throwsA(isA<TooManyRequests>()),
      );
    });

    test('token inexistente → TokenInvalid', () {
      expect(
        repo.verifyEmail('no-existe'),
        throwsA(isA<VerificationTokenInvalid>()),
      );
    });
  });

  group('HU-03 sesión', () {
    Future<void> registerAndVerify() async {
      await register();
      await repo.verifyEmail(tokenFor('nuevo@utez.edu.mx'));
    }

    test('credenciales correctas → JWT con expiración', () async {
      await registerAndVerify();
      final session = await repo.login(
        email: 'nuevo@utez.edu.mx',
        password: 'Segura123',
      );
      expect(session.accessToken, isNotEmpty);
      expect(session.expiresAt.isAfter(now), isTrue);
    });

    test('contraseña o correo incorrectos → el mismo error genérico', () async {
      await registerAndVerify();
      final wrongPassword = repo.login(
        email: 'nuevo@utez.edu.mx',
        password: 'Otra1234',
      );
      final unknownEmail = repo.login(
        email: 'nadie@utez.edu.mx',
        password: 'Segura123',
      );
      await expectLater(wrongPassword, throwsA(isA<InvalidCredentials>()));
      await expectLater(unknownEmail, throwsA(isA<InvalidCredentials>()));
    });

    test('una cuenta sin verificar no puede iniciar sesión', () async {
      await register();
      expect(
        repo.login(email: 'nuevo@utez.edu.mx', password: 'Segura123'),
        throwsA(isA<EmailNotVerified>()),
      );
    });

    test(
      'al cerrar sesión el token deja de servir en endpoints privados',
      () async {
        await registerAndVerify();
        final session = await repo.login(
          email: 'nuevo@utez.edu.mx',
          password: 'Segura123',
        );
        expect(
          (await repo.currentUser(session.accessToken)).email,
          'nuevo@utez.edu.mx',
        );
        await repo.logout(session.accessToken);
        expect(
          repo.currentUser(session.accessToken),
          throwsA(isA<SessionExpired>()),
        );
      },
    );

    test('un token vencido deja de servir en endpoints privados', () async {
      await registerAndVerify();
      final session = await repo.login(
        email: 'nuevo@utez.edu.mx',
        password: 'Segura123',
      );
      now = session.expiresAt;
      expect(
        repo.currentUser(session.accessToken),
        throwsA(isA<SessionExpired>()),
      );
    });
  });
}
