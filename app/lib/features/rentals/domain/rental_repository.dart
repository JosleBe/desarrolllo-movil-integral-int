import '../../catalog/domain/catalog_enums.dart';
import 'rental.dart';

/// Errores de dominio de las rentas (Épica 3).
sealed class RentalException implements Exception {
  const RentalException(this.message);
  final String message;
  @override
  String toString() => 'RentalException: $message';
}

/// El artículo ya está reservado en el lapso solicitado (RN-04, HU-13).
class DateOverlap extends RentalException {
  const DateOverlap()
    : super('El artículo ya está reservado en esas fechas');
}

/// El rango de fechas es inválido (fin antes del inicio, etc.).
class InvalidDateRange extends RentalException {
  const InvalidDateRange() : super('El rango de fechas no es válido');
}

/// El pago simulado falló; se puede reintentar (HU-14).
class PaymentFailed extends RentalException {
  const PaymentFailed()
    : super('El pago no se pudo procesar. Intenta de nuevo.');
}

/// La operación no es válida para el estado actual de la renta.
class InvalidRentalTransition extends RentalException {
  const InvalidRentalTransition(super.message);
}

/// Datos para solicitar una renta (HU-13).
class RentalRequest {
  const RentalRequest({
    required this.listingId,
    required this.period,
    required this.startDate,
    required this.endDate,
  });

  final String listingId;
  final RentalPeriod period;
  final DateTime startDate;
  final DateTime endDate;
}

/// Contrato de rentas (capa domain).
abstract interface class RentalRepository {
  /// Solicita una renta en estado SOLICITADA (HU-13).
  ///
  /// Valida el rango y el traslape de fechas (RN-04): si el artículo ya
  /// está reservado en ese lapso, lanza [DateOverlap].
  Future<Rental> request({
    required String renterId,
    required String renterName,
    required RentalRequest request,
  });

  /// Paga una renta en SOLICITADA (HU-14). Simula la pasarela: si
  /// [forceSuccess] es false, falla con [PaymentFailed] para probar el
  /// reintento. Con éxito, transiciona PAGADA → CONFIRMADA y genera el
  /// boleto con QR (HU-15).
  Future<Rental> pay({required String rentalId, bool forceSuccess = true});

  /// Cancela una renta en estado SOLICITADA (HU-16). Libera la reserva.
  Future<Rental> cancel({required String rentalId});

  /// Rentas del rentador dado.
  Future<List<Rental>> listForRenter(String renterId);

  /// Rentas de los artículos de un vendedor (HU-12).
  Future<List<Rental>> listForSeller(String ownerId);

  /// Devuelve una renta por id.
  Future<Rental?> findById(String rentalId);

  // --- Recepción (Épica 4) ---------------------------------------------

  /// Busca la renta asociada a un token de QR, o `null` si no existe.
  Future<Rental?> findByQrToken(String token);

  /// Registra la recepción del artículo entregado por el Vendedor (HU-19):
  /// transiciona CONFIRMADA → EN RECEPCIÓN y guarda el estado del artículo
  /// y el responsable.
  Future<Rental> receiveFromSeller({
    required String rentalId,
    required String itemCondition,
    required String receivedBy,
  });

  /// Registra la entrega del artículo al Rentador (HU-20, RN-05):
  /// transiciona EN RECEPCIÓN → ENTREGADA → EN RENTA e invalida el QR
  /// usado (HU-17). Lanza [InvalidRentalTransition] si no está en
  /// EN RECEPCIÓN.
  Future<Rental> deliverToRenter({required String rentalId});

  /// Registra la devolución del Rentador y el retorno al Vendedor (HU-21):
  /// transiciona EN RENTA → DEVUELTA → FINALIZADA.
  Future<Rental> registerReturn({
    required String rentalId,
    required String itemCondition,
  });

  /// Marca la renta en estado INCIDENCIA al reportarse un problema (HU-22).
  Future<Rental> markIncidence({required String rentalId});
}
