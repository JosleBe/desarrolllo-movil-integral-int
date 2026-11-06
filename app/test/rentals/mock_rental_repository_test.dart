import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/catalog/domain/catalog_enums.dart';
import 'package:sruu/features/rentals/data/mock_rental_repository.dart';
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

  Future<Rental> createSolicitada() => repo.request(
        renterId: 'u-1',
        renterName: 'Rentador 1',
        request: requestFor(),
      );

  group('solicitar renta (HU-13)', () {
    test('crea renta en estado SOLICITADA', () async {
      final rental = await repo.request(
        renterId: 'u-1',
        renterName: 'Rentador 1',
        request: requestFor(),
      );
      expect(rental.status, RentalStatus.requested);
      expect(rental.amount, greaterThan(0));
    });

    test('rechaza rango de fechas inválido', () {
      final now = DateTime.now();
      expect(
        () => repo.request(
          renterId: 'u-1',
          renterName: 'Rentador 1',
          request: RentalRequest(
            listingId: 'l-x',
            period: RentalPeriod.day,
            startDate: now.add(const Duration(days: 3)),
            endDate: now.add(const Duration(days: 1)),
          ),
        ),
        throwsA(isA<InvalidDateRange>()),
      );
    });

    test('rechaza traslape de fechas en el mismo artículo (RN-04)',
        () async {
      await repo.request(
        renterId: 'u-1',
        renterName: 'Rentador 1',
        request: requestFor(listingId: 'l-ov', startOffsetDays: 1,
            endOffsetDays: 5),
      );
      // Segundo intento que se solapa con el primero.
      expect(
        () => repo.request(
          renterId: 'u-2',
          renterName: 'Rentador 2',
          request: requestFor(listingId: 'l-ov', startOffsetDays: 3,
              endOffsetDays: 6),
        ),
        throwsA(isA<DateOverlap>()),
      );
    });

    test('permite reservar fechas no solapadas del mismo artículo',
        () async {
      await repo.request(
        renterId: 'u-1',
        renterName: 'Rentador 1',
        request: requestFor(listingId: 'l-seq', startOffsetDays: 1,
            endOffsetDays: 3),
      );
      final second = await repo.request(
        renterId: 'u-2',
        renterName: 'Rentador 2',
        request: requestFor(listingId: 'l-seq', startOffsetDays: 4,
            endOffsetDays: 6),
      );
      expect(second.status, RentalStatus.requested);
    });
  });

  group('pago (HU-14) y QR (HU-15)', () {
    test('pago fallido deja la renta en SOLICITADA para reintentar',
        () async {
      final rental = await createSolicitada();
      var threw = false;
      try {
        await repo.pay(rentalId: rental.id, forceSuccess: false);
      } on PaymentFailed {
        threw = true;
      }
      expect(threw, isTrue);
      final again = await repo.findById(rental.id);
      expect(again!.status, RentalStatus.requested);
    });

    test('pago exitoso confirma la renta y genera el boleto con QR',
        () async {
      final rental = await createSolicitada();
      final confirmed = await repo.pay(rentalId: rental.id);

      expect(confirmed.status, RentalStatus.confirmed);
      expect(confirmed.payment, isNotNull);
      expect(confirmed.ticket, isNotNull);
      expect(confirmed.ticket!.isValidAt(DateTime.now()), isTrue);
    });

    test('el token del QR es único entre rentas', () async {
      final a = await repo.request(
        renterId: 'u-1',
        renterName: 'R1',
        request: requestFor(listingId: 'l-a'),
      );
      final b = await repo.request(
        renterId: 'u-1',
        renterName: 'R1',
        request: requestFor(listingId: 'l-b'),
      );
      final ca = await repo.pay(rentalId: a.id);
      final cb = await repo.pay(rentalId: b.id);
      expect(ca.ticket!.token, isNot(equals(cb.ticket!.token)));
    });
  });

  group('cancelación (HU-16)', () {
    test('cancela una renta en SOLICITADA', () async {
      final rental = await createSolicitada();
      final cancelled = await repo.cancel(rentalId: rental.id);
      expect(cancelled.status, RentalStatus.cancelled);
    });

    test('no permite cancelar tras confirmar el pago', () async {
      final rental = await createSolicitada();
      await repo.pay(rentalId: rental.id);
      expect(
        () => repo.cancel(rentalId: rental.id),
        throwsA(isA<InvalidRentalTransition>()),
      );
    });

    test('tras cancelar, el artículo vuelve a poder reservarse', () async {
      final rental = await repo.request(
        renterId: 'u-1',
        renterName: 'R1',
        request: requestFor(listingId: 'l-free', startOffsetDays: 1,
            endOffsetDays: 3),
      );
      await repo.cancel(rentalId: rental.id);
      // Mismo lapso ahora disponible.
      final again = await repo.request(
        renterId: 'u-2',
        renterName: 'R2',
        request: requestFor(listingId: 'l-free', startOffsetDays: 1,
            endOffsetDays: 3),
      );
      expect(again.status, RentalStatus.requested);
    });
  });
}
