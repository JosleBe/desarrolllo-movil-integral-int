import 'user_permissions.dart';

/// Estado de la cuenta según el ciclo de vida del DFR (HU-01, HU-02).
///
/// Un registro nuevo nace [pendingVerification] y pasa a [verified] cuando
/// el usuario confirma su correo con el token (RN-01).
enum AccountStatus {
  /// Cuenta creada pero correo aún no verificado.
  pendingVerification,

  /// Correo verificado: ya es Usuario Base y puede iniciar sesión.
  verified,
}

/// Usuario de la comunidad UTEZ (Usuario Base) con sus permisos de cuenta.
///
/// El dominio no conoce JSON ni HTTP: es un modelo puro. La traducción
/// desde/hacia la API vive en la capa `data`.
class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.status = AccountStatus.pendingVerification,
    this.permissions = const UserPermissions(),
  });

  final String id;

  /// Correo institucional @utez.edu.mx. No es editable (HU-04).
  final String email;

  final String fullName;

  /// Dato de contacto editable por el usuario (HU-04).
  final String? phone;

  final AccountStatus status;

  final UserPermissions permissions;

  bool get isVerified => status == AccountStatus.verified;

  User copyWith({
    String? fullName,
    String? phone,
    AccountStatus? status,
    UserPermissions? permissions,
  }) {
    return User(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.email == email &&
      other.fullName == fullName &&
      other.phone == phone &&
      other.status == status &&
      other.permissions == permissions;

  @override
  int get hashCode =>
      Object.hash(id, email, fullName, phone, status, permissions);

  @override
  String toString() =>
      'User(id: $id, email: $email, status: $status, '
      'permissions: $permissions)';
}
