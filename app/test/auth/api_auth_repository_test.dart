import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/core/storage/token_storage.dart';
import 'package:sruu/features/auth/data/api_auth_repository.dart';
import 'package:sruu/features/auth/domain/auth_exception.dart';
import 'package:sruu/features/auth/domain/auth_repository.dart';
import 'package:sruu/features/auth/domain/user.dart';

/// Respuesta preparada para una ruta.
class _Reply {
  const _Reply(this.status, [this.body]);
  final int status;
  final Object? body;
}

/// Servidor falso: responde según `MÉTODO /ruta` y guarda lo que recibe.
class _FakeServer implements HttpClientAdapter {
  final Map<String, _Reply> routes = {};
  final List<RequestOptions> requests = [];
  bool offline = false;

  Map<String, dynamic> bodyOf(String key) {
    final request = requests.lastWhere((r) => '${r.method} ${r.path}' == key);
    return request.data as Map<String, dynamic>;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'sin red',
      );
    }
    final reply =
        routes['${options.method} ${options.path}'] ?? const _Reply(404);
    return ResponseBody.fromString(
      reply.body == null ? '' : jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _userJson({
  String status = 'VERIFICADA',
  Map<String, bool> permissions = const {
    'renter': true,
    'seller': false,
    'reception': false,
    'admin': false,
  },
  String? phone,
}) => {
  'id': '6f1c2a3b-0000-4000-8000-000000000001',
  'email': 'ana@utez.edu.mx',
  'fullName': 'Ana López',
  'phone': ?phone,
  'status': status,
  'role': status == 'VERIFICADA' ? 'USUARIO_BASE' : 'NINGUNO',
  'permissions': permissions,
};

void main() {
  late _FakeServer server;
  late TokenStorage tokenStorage;
  late ApiAuthRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    tokenStorage = TokenStorage(const FlutterSecureStorage());
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = server;
    repository = ApiAuthRepository(dio, tokenStorage);
  });

  group('registro y verificación (HU-01, HU-02)', () {
    test('registra y deja la cuenta pendiente, sin código visible', () async {
      server.routes['POST /auth/register'] = _Reply(201, {
        'user': _userJson(status: 'PENDIENTE_VERIFICACION'),
      });

      final result = await repository.register(
        fullName: ' Ana López ',
        email: 'ANA@utez.edu.mx',
        password: 'password1',
      );

      expect(result.user.status, AccountStatus.pendingVerification);
      expect(result.devToken, isEmpty);
      expect(server.bodyOf('POST /auth/register'), {
        'fullName': 'Ana López',
        'email': 'ana@utez.edu.mx',
        'password': 'password1',
      });
    });

    test('rechazo de dominio → InvalidInstitutionalEmail', () {
      server.routes['POST /auth/register'] = const _Reply(422, {
        'code': 'INSTITUTIONAL_EMAIL_REQUIRED',
      });
      expect(
        repository.register(
          fullName: 'Ana',
          email: 'ana@gmail.com',
          password: 'password1',
        ),
        throwsA(isA<InvalidInstitutionalEmail>()),
      );
    });

    test('correo repetido → EmailAlreadyRegistered', () {
      server.routes['POST /auth/register'] = const _Reply(409, {
        'code': 'EMAIL_ALREADY_REGISTERED',
      });
      expect(
        repository.register(
          fullName: 'Ana',
          email: 'ana@utez.edu.mx',
          password: 'password1',
        ),
        throwsA(isA<EmailAlreadyRegistered>()),
      );
    });

    test('verifica enviando correo y código', () async {
      server.routes['POST /auth/verify'] = _Reply(200, {'user': _userJson()});

      final user = await repository.verifyEmail(
        email: 'ana@utez.edu.mx',
        token: ' 123456 ',
      );

      expect(user.isVerified, isTrue);
      expect(server.bodyOf('POST /auth/verify'), {
        'email': 'ana@utez.edu.mx',
        'code': '123456',
      });
    });

    for (final code in ['TOKEN_INVALID', 'TOKEN_EXPIRED']) {
      test('$code → InvalidVerificationToken', () {
        server.routes['POST /auth/verify'] = _Reply(400, {'code': code});
        expect(
          repository.verifyEmail(email: 'ana@utez.edu.mx', token: '000000'),
          throwsA(isA<InvalidVerificationToken>()),
        );
      });
    }

    test('demasiados intentos → TooManyAttempts', () {
      server.routes['POST /auth/verify'] = const _Reply(429, {
        'code': 'TOO_MANY_ATTEMPTS',
      });
      expect(
        repository.verifyEmail(email: 'ana@utez.edu.mx', token: '000000'),
        throwsA(isA<TooManyAttempts>()),
      );
    });

    test('reenviar devuelve código vacío (llega por correo)', () async {
      server.routes['POST /auth/verify/resend'] = const _Reply(202);
      expect(
        await repository.resendVerificationToken(email: 'ana@utez.edu.mx'),
        isEmpty,
      );
    });
  });

  group('sesión (HU-03)', () {
    test('login guarda el JWT y traduce el usuario con permisos', () async {
      server.routes['POST /auth/login'] = _Reply(200, {
        'accessToken': 'jwt.abc.def',
        'expiresAt': '2026-11-05T23:00:00Z',
        'user': _userJson(),
      });

      final user = await repository.login(
        email: 'ana@utez.edu.mx',
        password: 'password1',
      );

      expect(await tokenStorage.readAccessToken(), 'jwt.abc.def');
      expect(user.id, '6f1c2a3b-0000-4000-8000-000000000001');
      expect(user.permissions.renter, isTrue);
      expect(user.permissions.seller, isFalse);
    });

    test('credenciales incorrectas → mensaje genérico', () async {
      server.routes['POST /auth/login'] = const _Reply(401, {
        'code': 'INVALID_CREDENTIALS',
      });
      await expectLater(
        repository.login(email: 'ana@utez.edu.mx', password: 'mala'),
        throwsA(
          isA<InvalidCredentials>().having(
            (e) => e.message,
            'message',
            'Correo o contraseña incorrectos',
          ),
        ),
      );
      expect(await tokenStorage.readAccessToken(), isNull);
    });

    test('cuenta sin verificar → AccountNotVerified', () {
      server.routes['POST /auth/login'] = const _Reply(403, {
        'code': 'EMAIL_NOT_VERIFIED',
      });
      expect(
        repository.login(email: 'ana@utez.edu.mx', password: 'password1'),
        throwsA(isA<AccountNotVerified>()),
      );
    });

    test('logout revoca en el servidor con el token y lo borra', () async {
      await tokenStorage.saveAccessToken('jwt.abc.def');
      server.routes['POST /auth/logout'] = const _Reply(204);

      await repository.logout();

      expect(server.requests.single.path, '/auth/logout');
      expect(await tokenStorage.readAccessToken(), isNull);
    });

    test('logout sin red borra el token de todos modos', () async {
      await tokenStorage.saveAccessToken('jwt.abc.def');
      server.offline = true;

      await repository.logout();

      expect(await tokenStorage.readAccessToken(), isNull);
    });

    test('currentUser sin token no llama al servidor', () async {
      expect(await repository.currentUser(), isNull);
      expect(server.requests, isEmpty);
    });

    test('currentUser con token vigente restaura la sesión', () async {
      await tokenStorage.saveAccessToken('jwt.abc.def');
      server.routes['GET /auth/me'] = _Reply(200, _userJson());
      expect((await repository.currentUser())?.email, 'ana@utez.edu.mx');
    });

    test('currentUser con token revocado lo borra y devuelve null', () async {
      await tokenStorage.saveAccessToken('jwt.abc.def');
      server.routes['GET /auth/me'] = const _Reply(401);

      expect(await repository.currentUser(), isNull);
      expect(await tokenStorage.readAccessToken(), isNull);
    });

    test('currentUser sin red conserva el token', () async {
      await tokenStorage.saveAccessToken('jwt.abc.def');
      server.offline = true;

      expect(await repository.currentUser(), isNull);
      expect(await tokenStorage.readAccessToken(), 'jwt.abc.def');
    });
  });

  group('perfil y permisos (HU-04, HU-24/25)', () {
    test('actualiza solo nombre y teléfono', () async {
      server.routes['PATCH /users/me'] = _Reply(
        200,
        _userJson(phone: '7779998888'),
      );

      final user = await repository.updateProfile(
        fullName: 'Ana López',
        phone: '7779998888',
      );

      expect(user.phone, '7779998888');
      expect(server.bodyOf('PATCH /users/me'), {
        'fullName': 'Ana López',
        'phone': '7779998888',
      });
    });

    test('perfil restringido → PermissionDenied con el motivo', () {
      server.routes['PATCH /users/me'] = const _Reply(403, {
        'code': 'PROFILE_READ_ONLY',
        'message': 'Tu perfil está en modo solo lectura.',
      });
      expect(
        repository.updateProfile(fullName: 'Ana'),
        throwsA(
          isA<PermissionDenied>().having(
            (e) => e.message,
            'message',
            'Tu perfil está en modo solo lectura.',
          ),
        ),
      );
    });

    test('lista cuentas para el Administrador', () async {
      server.routes['GET /admin/users'] = _Reply(200, [_userJson()]);
      final users = await repository.listUsers();
      expect(users.single.fullName, 'Ana López');
    });

    test('cambia un solo permiso', () async {
      server.routes['PATCH /admin/users/u1/permissions'] = _Reply(
        200,
        _userJson(
          permissions: const {
            'renter': true,
            'seller': false,
            'reception': false,
            'admin': false,
          },
        ),
      );

      final user = await repository.setPermission(
        userId: 'u1',
        permission: ManagedPermission.seller,
        active: false,
      );

      expect(user.permissions.seller, isFalse);
      expect(user.permissions.renter, isTrue);
      expect(server.bodyOf('PATCH /admin/users/u1/permissions'), {
        'permission': 'SELLER',
        'active': false,
      });
    });
  });

  test('sin conexión → AuthNetworkError', () {
    server.offline = true;
    expect(
      repository.login(email: 'ana@utez.edu.mx', password: 'password1'),
      throwsA(isA<AuthNetworkError>()),
    );
  });
}
