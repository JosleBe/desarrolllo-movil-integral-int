import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/core/storage/token_storage.dart';
import 'package:sruu/features/auth/data/mock_auth_repository.dart';
import 'package:sruu/features/auth/domain/auth_exception.dart';
import 'package:sruu/features/auth/domain/user.dart';

void main() {
  late MockAuthRepository repository;
  late TokenStorage tokenStorage;

  setUp(() {
    // Respalda flutter_secure_storage con un mapa en memoria para las pruebas.
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    tokenStorage = TokenStorage(const FlutterSecureStorage());
    repository = MockAuthRepository(tokenStorage);
  });

  group('registro (HU-01, RN-01)', () {
    test('rechaza correo que no es @utez.edu.mx', () {
      expect(
        () => repository.register(
          fullName: 'Ana',
          email: 'ana@gmail.com',
          password: 'password1',
        ),
        throwsA(isA<InvalidInstitutionalEmail>()),
      );
    });

    test('crea cuenta pendiente de verificación con correo válido', () async {
      final result = await repository.register(
        fullName: 'Ana',
        email: 'ana@utez.edu.mx',
        password: 'password1',
      );

      expect(result.user.email, 'ana@utez.edu.mx');
      expect(result.user.status, AccountStatus.pendingVerification);
      expect(result.devToken, isNotEmpty);
    });

    test('rechaza correo ya registrado', () async {
      await repository.register(
        fullName: 'Ana',
        email: 'ana@utez.edu.mx',
        password: 'password1',
      );

      expect(
        () => repository.register(
          fullName: 'Ana 2',
          email: 'ana@utez.edu.mx',
          password: 'password2',
        ),
        throwsA(isA<EmailAlreadyRegistered>()),
      );
    });
  });

  group('verificación por token (HU-02)', () {
    test('token válido deja la cuenta verificada', () async {
      final reg = await repository.register(
        fullName: 'Ana',
        email: 'ana@utez.edu.mx',
        password: 'password1',
      );

      final user = await repository.verifyEmail(
        email: 'ana@utez.edu.mx',
        token: reg.devToken,
      );

      expect(user.status, AccountStatus.verified);
    });

    test('token inválido lanza InvalidVerificationToken', () async {
      await repository.register(
        fullName: 'Ana',
        email: 'ana@utez.edu.mx',
        password: 'password1',
      );

      expect(
        () => repository.verifyEmail(
          email: 'ana@utez.edu.mx',
          token: '000000',
        ),
        throwsA(isA<InvalidVerificationToken>()),
      );
    });

    test('token ya usado deja de ser válido', () async {
      final reg = await repository.register(
        fullName: 'Ana',
        email: 'ana@utez.edu.mx',
        password: 'password1',
      );
      await repository.verifyEmail(
        email: 'ana@utez.edu.mx',
        token: reg.devToken,
      );

      expect(
        () => repository.verifyEmail(
          email: 'ana@utez.edu.mx',
          token: reg.devToken,
        ),
        throwsA(isA<InvalidVerificationToken>()),
      );
    });
  });

  group('login y logout (HU-03)', () {
    test('no permite login si la cuenta no está verificada', () async {
      await repository.register(
        fullName: 'Ana',
        email: 'ana@utez.edu.mx',
        password: 'password1',
      );

      expect(
        () => repository.login(
          email: 'ana@utez.edu.mx',
          password: 'password1',
        ),
        throwsA(isA<AccountNotVerified>()),
      );
    });

    test('login con credenciales incorrectas lanza InvalidCredentials', () {
      expect(
        () => repository.login(
          email: 'demo@utez.edu.mx',
          password: 'malapass',
        ),
        throwsA(isA<InvalidCredentials>()),
      );
    });

    test('login exitoso guarda el token y expone el usuario', () async {
      final user = await repository.login(
        email: 'demo@utez.edu.mx',
        password: 'demo1234',
      );

      expect(user.email, 'demo@utez.edu.mx');
      expect(await tokenStorage.readAccessToken(), isNotNull);
      expect(await repository.currentUser(), isNotNull);
    });

    test('logout limpia el token y la sesión', () async {
      await repository.login(
        email: 'demo@utez.edu.mx',
        password: 'demo1234',
      );
      await repository.logout();

      expect(await tokenStorage.readAccessToken(), isNull);
      expect(await repository.currentUser(), isNull);
    });
  });

  group('perfil (HU-04)', () {
    test('actualiza nombre y teléfono sin cambiar el correo', () async {
      await repository.login(
        email: 'demo@utez.edu.mx',
        password: 'demo1234',
      );

      final updated = await repository.updateProfile(
        fullName: 'Nombre Nuevo',
        phone: '7779998888',
      );

      expect(updated.fullName, 'Nombre Nuevo');
      expect(updated.phone, '7779998888');
      expect(updated.email, 'demo@utez.edu.mx');
    });
  });
}
