import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/auth/data/api_auth_repository.dart';
import 'package:sruu/features/auth/domain/auth_models.dart';

DioException httpError(int status, [Map<String, dynamic>? body]) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  test('mapea los códigos del contrato a fallas de dominio', () {
    expect(
      ApiAuthRepository.mapError(
        httpError(422, {'code': 'INSTITUTIONAL_EMAIL_REQUIRED'}),
      ),
      isA<InstitutionalEmailRequired>(),
    );
    expect(
      ApiAuthRepository.mapError(
        httpError(409, {'code': 'EMAIL_ALREADY_REGISTERED'}),
      ),
      isA<EmailAlreadyRegistered>(),
    );
    expect(
      ApiAuthRepository.mapError(
        httpError(410, {'code': 'TOKEN_EXPIRED', 'email': 'a@utez.edu.mx'}),
      ),
      isA<VerificationTokenExpired>().having(
        (f) => f.email,
        'email',
        'a@utez.edu.mx',
      ),
    );
    expect(
      ApiAuthRepository.mapError(
        httpError(409, {'code': 'TOKEN_ALREADY_USED'}),
      ),
      isA<VerificationTokenAlreadyUsed>(),
    );
    expect(
      ApiAuthRepository.mapError(
        httpError(403, {'code': 'EMAIL_NOT_VERIFIED'}),
        email: 'a@utez.edu.mx',
      ),
      isA<EmailNotVerified>().having((f) => f.email, 'email', 'a@utez.edu.mx'),
    );
  });

  test(
    'un 401 en login es credencial inválida; en endpoint privado, sesión vencida',
    () {
      expect(
        ApiAuthRepository.mapError(httpError(401), email: 'a@utez.edu.mx'),
        isA<InvalidCredentials>(),
      );
      expect(ApiAuthRepository.mapError(httpError(401)), isA<SessionExpired>());
    },
  );

  test('errores de conexión → NetworkFailure', () {
    final e = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    );
    expect(ApiAuthRepository.mapError(e), isA<NetworkFailure>());
  });
}
