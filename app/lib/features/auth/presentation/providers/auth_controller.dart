import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/token_storage.dart';
import '../../data/mock_auth_repository.dart';
import '../../domain/auth_exception.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user.dart';
import 'auth_state.dart';

/// Repositorio de autenticación.
///
/// Hoy devuelve el mock en memoria. Cuando exista el backend, basta
/// reemplazar esta línea por la implementación con Dio (`ApiAuthRepository`)
/// sin tocar controladores ni pantallas.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return MockAuthRepository(tokenStorage);
});

/// Controlador de sesión. Orquesta el repositorio y expone [AuthState].
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Resuelve la sesión previa (token guardado) al arrancar.
    _loadSession();
    return const AuthState.unknown();
  }

  Future<void> _loadSession() async {
    final user = await _repository.currentUser();
    state = AuthState(user: user);
  }

  /// Inicia sesión (HU-03). Devuelve `true` si fue exitoso.
  Future<bool> login({required String email, required String password}) {
    return _run(() => _repository.login(email: email, password: password));
  }

  /// Verifica el correo con el token y deja la sesión lista (HU-02).
  Future<bool> verifyEmail({required String email, required String token}) {
    return _run(
      () => _repository.verifyEmail(email: email, token: token),
      // Verificar no inicia sesión por sí solo; el usuario luego entra.
      authenticate: false,
    );
  }

  /// Actualiza datos de contacto del perfil (HU-04).
  Future<bool> updateProfile({String? fullName, String? phone}) {
    return _run(
      () => _repository.updateProfile(fullName: fullName, phone: phone),
    );
  }

  /// Cierra sesión e invalida el token (HU-03).
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Ejecuta una operación controlando loading, error y estado de sesión.
  Future<bool> _run(
    Future<User> Function() action, {
    bool authenticate = true,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await action();
      state = AuthState(user: authenticate ? user : state.user);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
      return false;
    }
  }
}
