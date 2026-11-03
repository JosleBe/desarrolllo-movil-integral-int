import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_models.dart';
import 'api_auth_repository.dart';
import 'fake_auth_repository.dart';

/// Contrato de autenticación (HU-01, HU-02, HU-03). Ver `docs/auth-api.md`.
abstract interface class AuthRepository {
  /// Crea la cuenta en estado [AccountStatus.pendingVerification] y dispara
  /// el envío del correo con el token de verificación.
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// Activa la cuenta: pasa a verificada con rol Usuario Base.
  Future<AuthUser> verifyEmail(String token);

  /// Invalida los tokens anteriores y envía uno nuevo. No revela si el
  /// correo existe.
  Future<void> resendVerification(String email);

  Future<AuthSession> login({required String email, required String password});

  /// Invalida el token en el servidor (lista de revocación).
  Future<void> logout(String accessToken);

  /// Endpoint privado: devuelve el usuario dueño del token.
  Future<AuthUser> currentUser(String accessToken);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Env.useFakeApi) return FakeAuthRepository();
  return ApiAuthRepository(ref.watch(dioProvider));
});
