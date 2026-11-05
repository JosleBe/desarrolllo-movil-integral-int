import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/auth/domain/user_permissions.dart';

void main() {
  group('matriz de permisos ABAC (DFR sección 5)', () {
    test('solo Rentador: no restringido, no completo', () {
      const p = UserPermissions(renter: true);
      expect(p.isRestricted, isFalse);
      expect(p.isFull, isFalse);
    });

    test('solo Vendedor: no restringido, no completo', () {
      const p = UserPermissions(seller: true);
      expect(p.isRestricted, isFalse);
      expect(p.isFull, isFalse);
    });

    test('ambos activos: perfil completo', () {
      const p = UserPermissions(renter: true, seller: true);
      expect(p.isFull, isTrue);
      expect(p.isRestricted, isFalse);
    });

    test('ninguno activo: perfil restringido', () {
      const p = UserPermissions();
      expect(p.isRestricted, isTrue);
      expect(p.isFull, isFalse);
    });

    test('copyWith cambia un permiso sin afectar el otro (RN-02)', () {
      const p = UserPermissions(renter: true, seller: true);
      final sinRenter = p.copyWith(renter: false);
      expect(sinRenter.renter, isFalse);
      expect(sinRenter.seller, isTrue);
    });
  });
}
