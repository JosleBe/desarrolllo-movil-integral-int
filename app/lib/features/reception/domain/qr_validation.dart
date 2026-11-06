import '../../rentals/domain/rental.dart';

/// Motivo por el que un QR es rechazado en Recepción (HU-17, HU-18).
enum QrRejectionReason {
  malformed('El código no tiene un formato válido'),
  notFound('No se encontró la transacción del código'),
  badSignature('La firma del código no es válida'),
  wrongPhase('El código no corresponde a esta fase'),
  expired('El código está vencido'),
  alreadyUsed('El código ya fue utilizado');

  const QrRejectionReason(this.message);
  final String message;
}

/// Resultado de validar un QR escaneado (HU-18).
///
/// Es un tipo sellado: o bien el QR es válido y trae la renta asociada
/// ([QrValid]), o fue rechazado con un motivo claro ([QrRejected]).
sealed class QrValidationResult {
  const QrValidationResult();
}

/// QR válido: expone la renta para mostrar artículo, rentador y vendedor.
class QrValid extends QrValidationResult {
  const QrValid(this.rental);
  final Rental rental;
}

/// QR rechazado con un motivo (falso, vencido, de otra fase, usado...).
class QrRejected extends QrValidationResult {
  const QrRejected(this.reason);
  final QrRejectionReason reason;
}
