import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/core/storage/token_storage.dart';
import 'package:sruu/features/auth/data/mock_auth_repository.dart';
import 'package:sruu/features/auth/domain/auth_repository.dart';

void main() {
  late MockAuthRepository auth;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    auth = MockAuthRepository(TokenStorage(const FlutterSecureStorage()));
  });

  group('gestión de permisos (HU-24/25)', () {
    test('listUsers incluye las cuentas de ejemplo', () async {
      final users = await auth.listUsers();
      expect(users.length, greaterThanOrEqualTo(3));
    });

    test('suspender Vendedor no afecta a Rentador (RN-02)', () async {
      // Laura tiene renter + seller activos.
      final users = await auth.listUsers();
      final laura = users.firstWhere((u) => u.id == 'u-laura');
      expect(laura.permissions.renter, isTrue);
      expect(laura.permissions.seller, isTrue);

      final updated = await auth.setPermission(
        userId: 'u-laura',
        permission: ManagedPermission.seller,
        active: false,
      );

      expect(updated.permissions.seller, isFalse);
      // El permiso de Rentador se mantiene intacto (RN-02).
      expect(updated.permissions.renter, isTrue);
    });

    test('reactivar un permiso individual lo vuelve a activar', () async {
      await auth.setPermission(
        userId: 'u-pedro',
        permission: ManagedPermission.seller,
        active: false,
      );
      final reactivated = await auth.setPermission(
        userId: 'u-pedro',
        permission: ManagedPermission.seller,
        active: true,
      );
      expect(reactivated.permissions.seller, isTrue);
    });
  });
}
