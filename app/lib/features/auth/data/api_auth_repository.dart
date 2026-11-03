import 'package:dio/dio.dart';

import '../domain/auth_models.dart';
import 'auth_repository.dart';

/// Implementación contra el backend REST. Los errores llegan como
/// `{ "code": "...", "message": "..." }`; ver `docs/auth-api.md`.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
  }) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'fullName': fullName, 'email': email, 'password': password},
    );
    return AuthUser.fromJson(res.data!['user'] as Map<String, dynamic>);
  });

  @override
  Future<AuthUser> verifyEmail(String token) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/verify',
      data: {'token': token},
    );
    return AuthUser.fromJson(res.data!['user'] as Map<String, dynamic>);
  });

  @override
  Future<void> resendVerification(String email) => _guard(
    () => _dio.post<void>('/auth/verify/resend', data: {'email': email}),
  );

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = res.data!;
    return AuthSession(
      accessToken: data['accessToken'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }, email: email);

  @override
  Future<void> logout(String accessToken) => _guard(
    () => _dio.post<void>(
      '/auth/logout',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    ),
  );

  @override
  Future<AuthUser> currentUser(String accessToken) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return AuthUser.fromJson(res.data!);
  });

  Future<T> _guard<T>(Future<T> Function() call, {String? email}) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapError(e, email: email);
    }
  }

  static AuthFailure mapError(DioException e, {String? email}) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkFailure();
      default:
        break;
    }

    final status = e.response?.statusCode;
    final body = e.response?.data;
    final code = body is Map ? body['code'] as String? : null;
    final tokenEmail = body is Map ? body['email'] as String? : null;

    switch (code) {
      case 'INSTITUTIONAL_EMAIL_REQUIRED':
        return const InstitutionalEmailRequired();
      case 'EMAIL_ALREADY_REGISTERED':
        return const EmailAlreadyRegistered();
      case 'INVALID_CREDENTIALS':
        return const InvalidCredentials();
      case 'EMAIL_NOT_VERIFIED':
        return EmailNotVerified(email ?? tokenEmail ?? '');
      case 'TOKEN_EXPIRED':
        return VerificationTokenExpired(email: tokenEmail);
      case 'TOKEN_ALREADY_USED':
        return VerificationTokenAlreadyUsed(email: tokenEmail);
      case 'TOKEN_INVALID':
        return const VerificationTokenInvalid();
      case 'RATE_LIMITED':
        return const TooManyRequests();
    }

    return switch (status) {
      401 =>
        email != null ? const InvalidCredentials() : const SessionExpired(),
      429 => const TooManyRequests(),
      _ => UnexpectedFailure('HTTP $status'),
    };
  }
}
