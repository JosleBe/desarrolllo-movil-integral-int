/// Reglas de validación de la Épica 1 (RN-01). El backend repite estas
/// validaciones; aquí solo dan retroalimentación inmediata.
abstract final class AuthValidators {
  static const institutionalDomain = 'utez.edu.mx';

  // Parte local estándar; el dominio debe ser exactamente utez.edu.mx
  // (sin subdominios ni dominios que solo "terminen" parecido).
  static final _institutionalEmail = RegExp(
    r'^[a-z0-9](?:[a-z0-9._%+-]{0,62}[a-z0-9])?@utez\.edu\.mx$',
  );

  static String normalizeEmail(String raw) => raw.trim().toLowerCase();

  static bool isInstitutionalEmail(String raw) {
    final email = normalizeEmail(raw);
    return _institutionalEmail.hasMatch(email) && !email.contains('..');
  }

  static const domainMessage =
      'Ese correo no es de la UTEZ. Solo se aceptan correos @utez.edu.mx.';

  /// Valida un correo completo.
  static String? email(String? value) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) return 'Falta tu correo institucional.';
    if (!email.contains('@') || email.split('@').length != 2) {
      return 'Escribe un correo válido, por ejemplo 20243tn001@utez.edu.mx.';
    }
    if (!isInstitutionalEmail(email)) return domainMessage;
    return null;
  }

  /// Valida lo que el usuario escribe antes del dominio fijo. Si pega un
  /// correo completo, se valida ese correo (y se rechaza otro dominio).
  static String? institutionalLocal(String? value) {
    final raw = normalizeEmail(value ?? '');
    if (raw.isEmpty) return 'Falta tu matrícula o usuario.';
    if (raw.contains('@')) {
      return isInstitutionalEmail(raw) ? null : domainMessage;
    }
    return isInstitutionalEmail('$raw@$institutionalDomain')
        ? null
        : 'Revisa tu usuario: usa solo letras, números, punto o guion.';
  }

  /// Arma el correo completo a partir de la matrícula (o del correo pegado).
  static String composeEmail(String value) {
    final raw = normalizeEmail(value);
    return raw.contains('@') ? raw : '$raw@$institutionalDomain';
  }

  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Falta tu nombre.';
    if (name.length < 3) return 'Escribe tu nombre completo.';
    if (name.length > 120) return 'Usa máximo 120 caracteres.';
    return null;
  }

  static const passwordMinLength = 8;

  static List<PasswordRule> passwordRules(String password) => [
    PasswordRule(
      '$passwordMinLength caracteres o más',
      password.length >= passwordMinLength,
    ),
    PasswordRule(
      'mayúscula y minúscula',
      password.contains(RegExp('[A-ZÁÉÍÓÚÑ]')) &&
          password.contains(RegExp('[a-záéíóúñ]')),
    ),
    PasswordRule('un número', password.contains(RegExp(r'\d'))),
  ];

  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Falta tu clave.';
    if (password.length > 72) return 'Usa máximo 72 caracteres.';
    final unmet = passwordRules(password).where((r) => !r.met);
    return unmet.isEmpty
        ? null
        : 'A tu clave le falta: ${unmet.map((r) => r.label).join(', ')}.';
  }

  static String? passwordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) return 'Repite tu clave.';
    return value == password ? null : 'Las dos claves no coinciden.';
  }

  /// Extrae el token de verificación de un enlace completo o lo devuelve tal
  /// cual si el usuario pegó solo el código.
  static String? extractVerificationToken(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    final fromQuery = uri?.queryParameters['token'];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    final fragment = uri?.fragment ?? '';
    if (fragment.contains('token=')) {
      return Uri.tryParse(fragment)?.queryParameters['token'];
    }
    return RegExp(r'^[A-Za-z0-9_-]{16,}$').hasMatch(text) ? text : null;
  }
}

class PasswordRule {
  const PasswordRule(this.label, this.met);
  final String label;
  final bool met;
}
