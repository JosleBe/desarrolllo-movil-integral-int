/// Estado de la cuenta según el backend.
enum AccountStatus {
  pendingVerification('PENDIENTE_VERIFICACION'),
  verified('VERIFICADA');

  const AccountStatus(this.apiValue);
  final String apiValue;

  static AccountStatus fromApi(String value) => values.firstWhere(
    (s) => s.apiValue == value,
    orElse: () => AccountStatus.pendingVerification,
  );
}

/// Rol asignado. Al verificar el correo la cuenta recibe [base].
enum UserRole {
  none('NINGUNO'),
  base('USUARIO_BASE');

  const UserRole(this.apiValue);
  final String apiValue;

  static UserRole fromApi(String? value) => values.firstWhere(
    (r) => r.apiValue == value,
    orElse: () => UserRole.none,
  );
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.status,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'].toString(),
    email: json['email'] as String,
    fullName: json['fullName'] as String? ?? '',
    status: AccountStatus.fromApi(json['status'] as String),
    role: UserRole.fromApi(json['role'] as String?),
  );

  final String id;
  final String email;
  final String fullName;
  final AccountStatus status;
  final UserRole role;

  bool get isVerified => status == AccountStatus.verified;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;
}

/// Sesión emitida por el backend al iniciar sesión (JWT con expiración).
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final DateTime expiresAt;
  final AuthUser user;
}

/// Errores de autenticación con significado para la interfaz.
sealed class AuthFailure implements Exception {
  const AuthFailure();
}

/// El correo no pertenece al dominio @utez.edu.mx.
final class InstitutionalEmailRequired extends AuthFailure {
  const InstitutionalEmailRequired();
}

final class EmailAlreadyRegistered extends AuthFailure {
  const EmailAlreadyRegistered();
}

/// Credenciales incorrectas. Deliberadamente no indica qué dato falló.
final class InvalidCredentials extends AuthFailure {
  const InvalidCredentials();
}

final class EmailNotVerified extends AuthFailure {
  const EmailNotVerified(this.email);
  final String email;
}

final class VerificationTokenExpired extends AuthFailure {
  const VerificationTokenExpired({this.email});
  final String? email;
}

final class VerificationTokenAlreadyUsed extends AuthFailure {
  const VerificationTokenAlreadyUsed({this.email});
  final String? email;
}

final class VerificationTokenInvalid extends AuthFailure {
  const VerificationTokenInvalid();
}

/// Demasiados reenvíos o intentos en poco tiempo.
final class TooManyRequests extends AuthFailure {
  const TooManyRequests();
}

final class SessionExpired extends AuthFailure {
  const SessionExpired();
}

final class NetworkFailure extends AuthFailure {
  const NetworkFailure();
}

final class UnexpectedFailure extends AuthFailure {
  const UnexpectedFailure([this.detail]);
  final String? detail;
}
