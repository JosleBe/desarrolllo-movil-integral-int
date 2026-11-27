import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/catalog/domain/catalog_enums.dart';
import 'package:sruu/features/rentals/data/mock_rental_repository.dart';
import 'package:sruu/features/rentals/domain/earnings_period.dart';
import 'package:sruu/features/rentals/domain/rental.dart';
import 'package:sruu/features/rentals/domain/rental_repository.dart';
import 'package:sruu/features/rentals/domain/rental_status.dart';

void main() {
  late MockRentalRepository repo;

  setUp(() => repo = MockRentalRepository());

  RentalRequest requestFor({
    String listingId = 'l-test',
    int startOffsetDays = 1,
    int endOffsetDays = 3,
  }) {
    final now = DateTime.now();
    return RentalRequest(
      listingId: listingId,
      period: RentalPeriod.day,
      startDate: now.add(Duration(days: startOffsetDays)),
      endDate: now.add(Duration(days: endOffsetDays)),
    );
  }

  Future<Rental> createPendingRental() => repo.request(
        renterId: 'u-1',
        renterName: 'Rentador 1',
        request: requestFor(),
      );

  group('solicitar renta y aprobación/rechazo (HU-13, HU-38)', () {
    test('crea renta en estado PENDIENTE_APROBACION', () async {
      final rental = await createPendingRental();
      expect(rental.status, RentalStatus.pendingApproval);
      expect(rental.isPendingApproval, isTrue);
      expect(rental.amount, greaterThan(0));
    });

    test('no permite pagar una solicitud no aprobada (HU-38)', () async {
      final rental = await createPendingRental();
      expect(
        () => repo.pay(rentalId: rental.id),
        throwsA(isA<InvalidRentalTransition>()),
      );
    });

    test('aprobar una solicitud cambia el estado a APROBADA y habilita el pago',
        () async {
      final rental = await createPendingRental();
      final approved = await repo.approve(rentalId: rental.id);

      expect(approved.status, RentalStatus.approved);
      expect(approved.isApproved, isTrue);
      expect(approved.canPay, isTrue);

      final confirmed = await repo.pay(rentalId: approved.id);
      expect(confirmed.status, RentalStatus.confirmed);
    });

    test('rechazar una solicitud cambia el estado a RECHAZADA y guarda el motivo',
        () async {
      final rental = await createPendingRental();
      final rejected = await repo.reject(
        rentalId: rental.id,
        reason: 'Artículo no disponible en esas fechas',
      );

      expect(rejected.status, RentalStatus.rejected);
      expect(rejected.isRejected, isTrue);
      expect(rejected.rejectionReason, equals('Artículo no disponible en esas fechas'));
      expect(rejected.canPay, isFalse);
    });
  });

  group('historial de pagos (HU-36)', () {
    test('listPaymentHistory devuelve solo rentas pagadas del rentador', () async {
      final pending = await createPendingRental();
      final approved = await repo.approve(rentalId: pending.id);
      await repo.pay(rentalId: approved.id);

      final history = await repo.listPaymentHistory('u-1');
      expect(history, isNotEmpty);
      expect(history.every((r) => r.payment != null), isTrue);
    });
  });

  group('ganancias del Vendedor (HU-37)', () {
    test('calcula ingresos agregados para el Vendedor demo', () async {
      final earnings = await repo.getSellerEarnings(
        ownerId: 'u-demo',
        period: EarningsPeriod.all,
      );

      expect(earnings.totalEarnings, greaterThan(0));
      expect(earnings.totalRentalsCount, greaterThan(0));
      expect(earnings.byListing, isNotEmpty);
    });

    test('retorna estado vacío si el vendedor no tiene ingresos', () async {
      final earnings = await repo.getSellerEarnings(
        ownerId: 'u-vendedor-sin-ventas',
        period: EarningsPeriod.all,
      );

      expect(earnings.isEmpty, isTrue);
      expect(earnings.totalEarnings, equals(0.0));
      expect(earnings.byListing, isEmpty);
    });
  });
}
