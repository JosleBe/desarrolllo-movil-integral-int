/// Errores de autenticación expresados en el lenguaje del dominio.
///
/// La capa `data` traduce fallos técnicos (HTTP, red, mock) a estas
/// excepciones para que la presentación muestre mensajes claros sin
/// conocer detalles de infraestructura.
sealed class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// El correo no pertenece al dominio @utez.edu.mx (RN-01).
class InvalidInstitutionalEmail extends AuthException {
  const InvalidInstitutionalEmail()
    : super('Usa tu correo institucional @utez.edu.mx');
}

/// Ya existe una cuenta registrada con ese correo (correo único, HU-01).
class EmailAlreadyRegistered extends AuthException {
  const EmailAlreadyRegistered()
    : super('Ya existe una cuenta con ese correo');
}

/// Credenciales incorrectas. Mensaje genérico a propósito (HU-03): no
/// revela si falló el correo o la contraseña.
class InvalidCredentials extends AuthException {
  const InvalidCredentials() : super('Correo o contraseña incorrectos');
}

/// La cuenta existe pero el correo aún no se ha verificado (HU-02).
class AccountNotVerified extends AuthException {
  const AccountNotVerified()
    : super('Verifica tu correo antes de iniciar sesión');
}

/// El token de verificación no es válido, está vencido o ya se usó (HU-02).
class InvalidVerificationToken extends AuthException {
  const InvalidVerificationToken()
    : super('El código de verificación no es válido o ya expiró');
}
