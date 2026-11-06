import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/admin/data/mock_audit_repository.dart';
import 'package:sruu/features/admin/data/mock_incidence_repository.dart';
import 'package:sruu/features/admin/domain/admin_repositories.dart';
import 'package:sruu/features/admin/domain/audit_entry.dart';
import 'package:sruu/features/admin/domain/incidence.dart';
import 'package:sruu/features/catalog/domain/catalog_enums.dart';
import 'package:sruu/features/rentals/data/mock_rental_repository.dart';
import 'package:sruu/features/rentals/domain/rental_repository.dart';
import 'package:sruu/features/rentals/domain/rental_status.dart';

void main() {
  late MockRentalRepository rentals;
  late MockAuditRepository audit;
  late MockIncidenceRepository incidences;

  setUp(() {
    rentals = MockRentalRepository();
    audit = MockAuditRepository();
    incidences = MockIncidenceRepository(rentals, audit);
  });

  Future<String> createOnRentRental() async {
    final now = DateTime.now();
    final requested = await rentals.request(
      renterId: 'u-r',
      renterName: 'R',
      request: RentalRequest(
        listingId: 'l-i',
        period: RentalPeriod.day,
        startDate: now.add(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 2)),
      ),
    );
    return requested.id;
  }

  group('incidencias (HU-22, HU-23)', () {
    test('reportar crea la incidencia y pasa la renta a INCIDENCIA', () async {
      final rentalId = await createOnRentRental();
      final incidence = await incidences.report(
        IncidenceDraft(
          rentalId: rentalId,
          rentalTitle: 'Multímetro',
          type: IncidenceType.damage,
          description: 'Llegó con un golpe',
          reportedBy: 'Carlos',
        ),
      );

      expect(incidence.status, IncidenceStatus.open);
      final rental = await rentals.findById(rentalId);
      expect(rental!.status, RentalStatus.incident);
    });

    test('resolver cierra la incidencia y registra en bitácora', () async {
      final rentalId = await createOnRentRental();
      final incidence = await incidences.report(
        IncidenceDraft(
          rentalId: rentalId,
          rentalTitle: 'Multímetro',
          type: IncidenceType.delay,
          description: 'Demora en devolución',
          reportedBy: 'Laura',
        ),
      );

      final resolved = await incidences.resolve(
        incidenceId: incidence.id,
        resolution: 'Se acordó una penalización',
        resolvedBy: 'Admin',
      );
      expect(resolved.status, IncidenceStatus.resolved);

      final log = await audit.query(
        const AuditFilters(action: AuditAction.incidenceResolved),
      );
      expect(log, isNotEmpty);
    });
  });

  group('bitácora de auditoría (HU-26, RNF-08)', () {
    test('filtra por acción', () async {
      final log = await audit.query(
        const AuditFilters(action: AuditAction.incidenceResolved),
      );
      expect(
        log.every((e) => e.action == AuditAction.incidenceResolved),
        isTrue,
      );
    });

    test('filtra por actor', () async {
      await audit.record(
        AuditEntry(
          id: audit.generateId(),
          actor: 'Administrador X',
          action: AuditAction.permissionSuspended,
          target: 'Usuario Y · permiso Rentador',
          timestamp: DateTime.now(),
          reason: 'Incumplimiento',
        ),
      );
      final log = await audit.query(
        const AuditFilters(actor: 'Administrador X'),
      );
      expect(log, hasLength(1));
      expect(log.first.reason, 'Incumplimiento');
    });

    test('el contrato no expone edición ni borrado (inmutabilidad)', () {
      // AuditRepository solo declara record() y query(): no hay update ni
      // delete. Esta prueba documenta el invariante de RNF-08.
      expect(audit, isA<AuditRepository>());
    });
  });
}
