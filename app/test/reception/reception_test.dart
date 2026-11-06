import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/catalog/domain/catalog_enums.dart';
import 'package:sruu/features/reception/data/qr_validator.dart';
import 'package:sruu/features/reception/domain/qr_validation.dart';
import 'package:sruu/features/rentals/data/mock_rental_repository.dart';
import 'package:sruu/features/rentals/domain/rental.dart';
import 'package:sruu/features/rentals/domain/rental_repository.dart';
import 'package:sruu/features/rentals/domain/rental_status.dart';

void main() {
  late MockRentalRepository repo;
  late QrValidator validator;

  setUp(() {
    repo = MockRentalRepository();
    validator = QrValidator(repo);
  });

  /// Crea una renta confirmada con QR válido y devuelve (renta, payload).
  Future<(Rental, String)> confirmedWithTicket() async {
    final now = DateTime.now();
    final requested = await repo.request(
      renterId: 'u-ren',
      renterName: 'Rentador',
      request: RentalRequest(
        listingId: 'l-rec',
        period: RentalPeriod.day,
        startDate: now.add(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 3)),
      ),
    );
    final confirmed = await repo.pay(rentalId: requested.id);
    return (confirmed, confirmed.ticket!.payload);
  }

  group('validación de QR (HU-18, HU-17)', () {
    test('payload válido devuelve QrValid con la renta', () async {
      final (rental, payload) = await confirmedWithTicket();
      final result = await validator.validateForPickup(payload);
      expect(result, isA<QrValid>());
      expect((result as QrValid).rental.id, rental.id);
    });

    test('payload mal formado se rechaza', () async {
      final result = await validator.validateForPickup('no-es-un-qr');
      expect(result, isA<QrRejected>());
      expect(
        (result as QrRejected).reason,
        QrRejectionReason.malformed,
      );
    });

    test('firma inválida se rechaza', () async {
      final (_, payload) = await confirmedWithTicket();
      final parts = payload.split('|');
      final tampered = 'SRUU|${parts[1]}|${parts[2]}|firma-falsa';
      final result = await validator.validateForPickup(tampered);
      expect((result as QrRejected).reason, QrRejectionReason.badSignature);
    });

    test('token inexistente se rechaza', () async {
      final result = await validator.validateForPickup(
        'SRUU|QR-inexistente|pickup|abc',
      );
      expect((result as QrRejected).reason, QrRejectionReason.notFound);
    });

    test('QR ya usado se rechaza (HU-17)', () async {
      final (rental, payload) = await confirmedWithTicket();
      // Recibir y entregar consume el QR.
      await repo.receiveFromSeller(
        rentalId: rental.id,
        itemCondition: 'ok',
        receivedBy: 'Recepción',
      );
      await repo.deliverToRenter(rentalId: rental.id);
      final result = await validator.validateForPickup(payload);
      expect((result as QrRejected).reason, QrRejectionReason.alreadyUsed);
    });
  });

  group('transiciones de recepción (HU-19/20/21)', () {
    test('recibir confirma transición a EN RECEPCIÓN', () async {
      final (rental, _) = await confirmedWithTicket();
      final received = await repo.receiveFromSeller(
        rentalId: rental.id,
        itemCondition: 'Buen estado',
        receivedBy: 'Recepción',
      );
      expect(received.status, RentalStatus.inReception);
      expect(received.itemConditionNote, 'Buen estado');
      expect(received.receivedBy, 'Recepción');
    });

    test('no se puede entregar sin pasar por recepción (RN-05)', () async {
      final (rental, _) = await confirmedWithTicket();
      // Intentar entregar directo desde CONFIRMADA debe fallar.
      expect(
        () => repo.deliverToRenter(rentalId: rental.id),
        throwsA(isA<InvalidRentalTransition>()),
      );
    });

    test('entregar pasa a EN RENTA e invalida el QR (HU-17)', () async {
      final (rental, _) = await confirmedWithTicket();
      await repo.receiveFromSeller(
        rentalId: rental.id,
        itemCondition: 'ok',
        receivedBy: 'Recepción',
      );
      final delivered = await repo.deliverToRenter(rentalId: rental.id);
      expect(delivered.status, RentalStatus.onRent);
      expect(delivered.ticket!.used, isTrue);
      expect(delivered.ticket!.isValidAt(DateTime.now()), isFalse);
    });

    test('registrar devolución pasa a FINALIZADA', () async {
      final (rental, _) = await confirmedWithTicket();
      await repo.receiveFromSeller(
        rentalId: rental.id,
        itemCondition: 'ok',
        receivedBy: 'Recepción',
      );
      await repo.deliverToRenter(rentalId: rental.id);
      final finished = await repo.registerReturn(
        rentalId: rental.id,
        itemCondition: 'Sin daños',
      );
      expect(finished.status, RentalStatus.finished);
    });
  });
}
