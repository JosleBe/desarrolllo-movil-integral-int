import 'package:dio/dio.dart';

import '../../../core/storage/token_storage.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import '../domain/user_permissions.dart';

/// Implementación de [AuthRepository] contra el backend REST (Spring Boot).
///
/// Cumple el mismo contrato que [MockAuthRepository], así que la UI y los
/// controladores no cambian. Traduce el JSON del backend al dominio y cada
/// código de error (`{code, message}`) a una [AuthException]. Contrato
/// completo en `docs/auth-api.md`.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
    // En producción el código solo viaja por correo: no hay devToken.
    return RegistrationResult(
      user: userFromJson(res.data!['user'] as Map<String, dynamic>),
      devToken: '',
    );
  });

  @override
  Future<User> verifyEmail({required String email, required String token}) =>
      _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/verify',
          data: {'email': email.trim().toLowerCase(), 'code': token.trim()},
        );
        return userFromJson(res.data!['user'] as Map<String, dynamic>);
      });

  @override
  Future<String> resendVerificationToken({required String email}) =>
      _guard(() async {
        await _dio.post<void>(
          '/auth/verify/resend',
          data: {'email': email.trim().toLowerCase()},
        );
        return '';
      });

  @override
  Future<User> login({required String email, required String password}) =>
      _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'email': email.trim().toLowerCase(), 'password': password},
        );
        final data = res.data!;
        await _tokenStorage.saveAccessToken(data['accessToken'] as String);
        return userFromJson(data['user'] as Map<String, dynamic>);
      }, login: true);

  /// Invalida el JWT en el servidor (lista de revocación) y lo borra del
  /// dispositivo. Si el servidor no responde, el token local se borra igual.
  @override
  Future<void> logout() async {
    try {
      if (await _tokenStorage.readAccessToken() != null) {
        await _dio.post<void>('/auth/logout');
      }
    } on DioException {
      // El token expira por sí solo; lo importante es no conservarlo.
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// Restaura la sesión al arrancar. Nunca lanza: sin token, con token
  /// vencido/revocado o sin red, devuelve `null` y la app va al login.
  @override
  Future<User?> currentUser() async {
    if (await _tokenStorage.readAccessToken() == null) return null;
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      return userFromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await _tokenStorage.clear();
      return null;
    }
  }

  @override
  Future<User> updateProfile({String? fullName, String? phone}) =>
      _guard(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '/users/me',
          data: {'fullName': ?fullName, 'phone': ?phone},
        );
        return userFromJson(res.data!);
      });

  @override
  Future<List<User>> listUsers() => _guard(() async {
    final res = await _dio.get<List<dynamic>>('/admin/users');
    return res.data!
        .map((json) => userFromJson(json as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<User> setPermission({
    required String userId,
    required ManagedPermission permission,
    required bool active,
  }) => _guard(() async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/admin/users/$userId/permissions',
      data: {
        'permission': switch (permission) {
          ManagedPermission.renter => 'RENTER',
          ManagedPermission.seller => 'SELLER',
        },
        'active': active,
      },
    );
    return userFromJson(res.data!);
  });

  // --- Traducción JSON ⇄ dominio --------------------------------------

  /// Adapta el `UserResponse` del backend al modelo [User] del dominio.
  static User userFromJson(Map<String, dynamic> json) {
    final permissions = json['permissions'] as Map<String, dynamic>? ?? {};
    bool flag(String key) => permissions[key] as bool? ?? false;
    return User(
      id: json['id'].toString(),
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] == 'VERIFICADA'
          ? AccountStatus.verified
          : AccountStatus.pendingVerification,
      permissions: UserPermissions(
        renter: flag('renter'),
        seller: flag('seller'),
        reception: flag('reception'),
        admin: flag('admin'),
      ),
    );
  }

  /// Traduce un error HTTP del backend a una [AuthException] del dominio.
  ///
  /// [login] distingue un 401 de credenciales incorrectas de un 401 por
  /// sesión vencida en un endpoint privado.
  static AuthException mapError(DioException e, {bool login = false}) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const AuthNetworkError();
      default:
        break;
    }

    final status = e.response?.statusCode;
    final body = e.response?.data;
    final code = body is Map ? body['code'] as String? : null;
    final message = body is Map ? body['message'] as String? : null;

    switch (code) {
      case 'INSTITUTIONAL_EMAIL_REQUIRED':
        return const InvalidInstitutionalEmail();
      case 'EMAIL_ALREADY_REGISTERED':
        return const EmailAlreadyRegistered();
      case 'INVALID_CREDENTIALS':
        return const InvalidCredentials();
      case 'EMAIL_NOT_VERIFIED':
        return const AccountNotVerified();
      case 'TOKEN_INVALID':
      case 'TOKEN_EXPIRED':
      case 'TOKEN_ALREADY_USED':
        return const InvalidVerificationToken();
      case 'TOO_MANY_ATTEMPTS':
      case 'RATE_LIMITED':
        return const TooManyAttempts();
      case 'PROFILE_READ_ONLY':
      case 'FORBIDDEN':
        return PermissionDenied(
          message ?? 'No tienes permiso para esta acción',
        );
      case 'WEAK_PASSWORD':
        return InvalidAuthData(
          message ?? 'La contraseña debe tener entre 8 y 72 caracteres',
        );
      case 'VALIDATION_ERROR':
        return InvalidAuthData(_firstFieldError(body) ?? 'Revisa tus datos');
    }

    return switch (status) {
      401 => login ? const InvalidCredentials() : const SessionExpired(),
      403 => PermissionDenied(message ?? 'No tienes permiso para esta acción'),
      429 => const TooManyAttempts(),
      _ => const UnexpectedAuthError(),
    };
  }

  static String? _firstFieldError(Object? body) {
    final fields = body is Map ? body['fields'] : null;
    if (fields is Map && fields.isNotEmpty) {
      return fields.values.first?.toString();
    }
    return body is Map ? body['message'] as String? : null;
  }

  Future<T> _guard<T>(Future<T> Function() call, {bool login = false}) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapError(e, login: login);
    }
  }
}
