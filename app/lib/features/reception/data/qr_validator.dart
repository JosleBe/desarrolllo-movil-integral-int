import '../../rentals/domain/qr_ticket.dart';
import '../../rentals/domain/rental_repository.dart';
import '../domain/qr_validation.dart';

/// Valida el payload de un QR escaneado en Recepción (HU-18, HU-17).
///
/// Comprueba formato, firma, existencia de la transacción, fase y
/// vigencia/un-solo-uso. Devuelve [QrValid] con la renta o [QrRejected]
/// con el motivo. La firma aquí es simulada; el backend usaría
/// criptografía real (RNF-05).
class QrValidator {
  QrValidator(this._rentals);

  final RentalRepository _rentals;

  /// Fase esperada en el escaneo de entrega (HU-20).
  Future<QrValidationResult> validateForPickup(String rawPayload) {
    return _validate(rawPayload, QrPhase.pickup);
  }

  Future<QrValidationResult> _validate(
    String rawPayload,
    QrPhase expectedPhase,
  ) async {
    final payload = rawPayload.trim();
    // Formato: SRUU|<token>|<phase>|<signature>
    final parts = payload.split('|');
    if (parts.length != 4 || parts[0] != 'SRUU') {
      return const QrRejected(QrRejectionReason.malformed);
    }

    final token = parts[1];
    final phaseName = parts[2];
    final signature = parts[3];

    final rental = await _rentals.findByQrToken(token);
    final ticket = rental?.ticket;
    if (rental == null || ticket == null) {
      return const QrRejected(QrRejectionReason.notFound);
    }

    // La firma debe coincidir con la del boleto emitido.
    if (ticket.signature != signature) {
      return const QrRejected(QrRejectionReason.badSignature);
    }

    // La fase codificada y la esperada deben coincidir (HU-17).
    if (phaseName != expectedPhase.name || ticket.phase != expectedPhase) {
      return const QrRejected(QrRejectionReason.wrongPhase);
    }

    // Vigencia y un solo uso (HU-17).
    final state = ticket.stateAt(DateTime.now());
    return switch (state) {
      QrState.used => const QrRejected(QrRejectionReason.alreadyUsed),
      QrState.expired => const QrRejected(QrRejectionReason.expired),
      QrState.valid => QrValid(rental),
    };
  }
}
