import 'user.dart';

/// Resultado de un registro exitoso (HU-01 / HU-02).
///
/// En producción el token viaja por correo; para el mock lo exponemos
/// aquí para poder completar el flujo de verificación sin backend.
class RegistrationResult {
  const RegistrationResult({required this.user, required this.devToken});

  final User user;

  /// Token de verificación. Solo visible en desarrollo/mock.
  final String devToken;
}

/// Contrato de autenticación (capa domain).
///
/// La presentación depende de esta abstracción, nunca de una
/// implementación concreta. Hoy la cumple un mock en memoria; cuando
/// exista el backend, una implementación con Dio la reemplazará sin
/// cambiar la UI ni los controladores.
abstract interface class AuthRepository {
  /// Registra una cuenta nueva en estado pendiente de verificación.
  ///
  /// Lanza [InvalidInstitutionalEmail] si el correo no es @utez.edu.mx y
  /// [EmailAlreadyRegistered] si el correo ya existe.
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// Verifica el correo con el token recibido (HU-02).
  ///
  /// Lanza [InvalidVerificationToken] si el token es inválido/vencido.
  Future<User> verifyEmail({required String email, required String token});

  /// Reenvía un token de verificación para un correo pendiente (HU-02).
  Future<String> resendVerificationToken({required String email});

  /// Inicia sesión y devuelve el usuario autenticado (HU-03).
  ///
  /// Lanza [InvalidCredentials] con credenciales incorrectas y
  /// [AccountNotVerified] si la cuenta no ha verificado su correo.
  Future<User> login({required String email, required String password});

  /// Cierra la sesión e invalida el token actual (HU-03).
  Future<void> logout();

  /// Devuelve el usuario de la sesión vigente, o `null` si no hay sesión.
  Future<User?> currentUser();

  /// Actualiza datos de contacto del perfil (HU-04). El correo no cambia.
  Future<User> updateProfile({String? fullName, String? phone});

  // --- Administración de permisos (Épica 5) ----------------------------

  /// Lista las cuentas del sistema (panel del Administrador, HU-24/25).
  Future<List<User>> listUsers();

  /// Suspende un permiso individual de un usuario (HU-24).
  ///
  /// El [reason] es obligatorio (RN-03): si viene vacío, lanza
  /// [ReasonRequired] en la capa que orquesta. Suspender un permiso no
  /// afecta al otro (RN-02).
  Future<User> setPermission({
    required String userId,
    required ManagedPermission permission,
    required bool active,
  });
}

/// Permiso gestionable por el Administrador (HU-24/25).
enum ManagedPermission {
  renter('Rentador'),
  seller('Vendedor');

  const ManagedPermission(this.label);
  final String label;
}
