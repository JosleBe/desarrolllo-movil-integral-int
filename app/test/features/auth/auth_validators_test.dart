import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/auth/domain/auth_validators.dart';

void main() {
  group('correo institucional (HU-01, RN-01)', () {
    test(
      'acepta correos @utez.edu.mx, sin importar mayúsculas ni espacios',
      () {
        expect(
          AuthValidators.isInstitutionalEmail('20223tn067@utez.edu.mx'),
          isTrue,
        );
        expect(
          AuthValidators.isInstitutionalEmail('  Ana.Lopez@UTEZ.edu.mx '),
          isTrue,
        );
      },
    );

    for (final email in [
      'alguien@gmail.com',
      'alumno@utez.edu.mx.com',
      'alumno@fake.utez.edu.mx',
      'alumno@utez.edu',
      'alumno@utezedu.mx',
      '@utez.edu.mx',
      'a@b@utez.edu.mx',
      'a..b@utez.edu.mx',
      '',
    ]) {
      test('rechaza "$email"', () {
        expect(AuthValidators.isInstitutionalEmail(email), isFalse);
        expect(AuthValidators.email(email), isNotNull);
      });
    }

    test('el mensaje de dominio es claro', () {
      expect(
        AuthValidators.email('alguien@gmail.com'),
        contains('Solo se aceptan correos @utez.edu.mx'),
      );
    });
  });

  group('matrícula con dominio fijo (HU-01)', () {
    test('acepta la matrícula sola y arma el correo', () {
      expect(AuthValidators.institutionalLocal('20223TN067'), isNull);
      expect(
        AuthValidators.composeEmail(' 20223TN067 '),
        '20223tn067@utez.edu.mx',
      );
    });

    test('si pegan un correo de la UTEZ, lo acepta tal cual', () {
      expect(AuthValidators.institutionalLocal('ana@utez.edu.mx'), isNull);
      expect(AuthValidators.composeEmail('ana@utez.edu.mx'), 'ana@utez.edu.mx');
    });

    test(
      'si pegan un correo de otro dominio, lo rechaza con mensaje claro',
      () {
        expect(
          AuthValidators.institutionalLocal('alguien@gmail.com'),
          AuthValidators.domainMessage,
        );
      },
    );

    test('rechaza vacío y caracteres inválidos', () {
      expect(AuthValidators.institutionalLocal(''), isNotNull);
      expect(AuthValidators.institutionalLocal('ana lopez'), isNotNull);
    });
  });

  group('contraseña', () {
    test('exige longitud, mayúscula, minúscula y número', () {
      expect(AuthValidators.newPassword('corta1A'), isNotNull);
      expect(AuthValidators.newPassword('sinnumeroA'), isNotNull);
      expect(AuthValidators.newPassword('sinmayus1'), isNotNull);
      expect(AuthValidators.newPassword('Segura123'), isNull);
    });

    test('la confirmación debe coincidir', () {
      expect(AuthValidators.passwordConfirmation('x', 'y'), isNotNull);
      expect(
        AuthValidators.passwordConfirmation('Segura123', 'Segura123'),
        isNull,
      );
    });
  });

  group('token pegado (HU-02)', () {
    const token = 'AbCdEfGhIjKlMnOpQrStUvWxYz012345';

    test('extrae el token de un enlace completo o del código suelto', () {
      expect(
        AuthValidators.extractVerificationToken(
          'https://sruu.utez.edu.mx/verificar?token=$token',
        ),
        token,
      );
      expect(
        AuthValidators.extractVerificationToken(
          'https://sruu.app/#/verificar?token=$token',
        ),
        token,
      );
      expect(AuthValidators.extractVerificationToken(token), token);
    });

    test('ignora texto que no es un token', () {
      expect(AuthValidators.extractVerificationToken('hola'), isNull);
      expect(AuthValidators.extractVerificationToken(''), isNull);
    });
  });
}
