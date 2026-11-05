import '../../domain/user.dart';

/// Estado de la sesión de autenticación expuesto a la UI.
///
/// Es inmutable; el [AuthController] emite copias nuevas con [copyWith].
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Estado inicial mientras se resuelve si hay sesión previa.
  const AuthState.unknown() : this(isLoading: true);

  /// Usuario autenticado, o `null` si no hay sesión.
  final User? user;

  /// Hay una operación en curso (login, registro, etc.).
  final bool isLoading;

  /// Mensaje de error de la última operación, o `null` si no hubo.
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
