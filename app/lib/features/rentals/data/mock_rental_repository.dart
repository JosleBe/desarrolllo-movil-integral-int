import '../../catalog/domain/catalog_enums.dart';
import '../domain/payment.dart';
import '../domain/qr_ticket.dart';
import '../domain/rental.dart';
import '../domain/rental_repository.dart';
import '../domain/rental_status.dart';

/// Implementación en memoria de [RentalRepository] para trabajar sin
/// backend. Valida el traslape de fechas (RN-04) de forma real, aplica las
/// transiciones de estado del flujo del DFR, simula el pago y genera un
/// boleto con QR único tras la confirmación (HU-15).
class MockRentalRepository implements RentalRepository {
  MockRentalRepository() {
    _seed();
  }

  static const _delay = Duration(milliseconds: 400);

  /// Estados que ocupan el artículo y por tanto cuentan para el traslape.
  static const _blockingStates = {
    RentalStatus.requested,
    RentalStatus.paid,
    RentalStatus.confirmed,
    RentalStatus.inReception,
    RentalStatus.delivered,
    RentalStatus.onRent,
  };

  final Map<String, Rental> _rentals = {};
  int _idCounter = 0;
  int _tokenCounter = 0;

  void _seed() {
    final now = DateTime.now();
    // Una renta de ejemplo del Vendedor demo, ya en curso.
    final rental = Rental(
      id: _nextId(),
      listingId: 'l-0',
      listingTitle: 'Calculadora científica Casio fx-991',
      renterId: 'u-carlos',
      renterName: 'Carlos R.',
      ownerId: 'u-demo',
      ownerName: 'Usuario Demo',
      period: RentalPeriod.day,
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 2)),
      amount: 75,
      status: RentalStatus.onRent,
    );
    _rentals[rental.id] = rental;

    // Renta CONFIRMADA con boleto QR válido, lista para el flujo de
    // Recepción (recibir → entregar). El payload del QR se puede copiar
    // desde el boleto o usar el que imprime este seed para probar HU-18.
    final confirmed = Rental(
      id: _nextId(),
      listingId: 'l-3',
      listingTitle: 'Multímetro digital',
      renterId: 'u-maria',
      renterName: 'María G.',
      ownerId: 'u-demo',
      ownerName: 'Usuario Demo',
      period: RentalPeriod.day,
      startDate: now,
      endDate: now.add(const Duration(days: 3)),
      amount: 120,
      status: RentalStatus.confirmed,
    );
    final ticket = _generateTicket(confirmed);
    _rentals[confirmed.id] = confirmed.copyWith(ticket: ticket);
    seedPickupPayload = ticket.payload;
  }

  /// Payload del QR de la renta confirmada del seed, para pruebas de
  /// Recepción (HU-18): se puede pegar en el escáner manual.
  String seedPickupPayload = '';

  String _nextId() => 'r-${_idCounter++}';

  @override
  Future<Rental> request({
    required String renterId,
    required String renterName,
    required RentalRequest request,
  }) async {
    await Future<void>.delayed(_delay);

    if (!request.endDate.isAfter(request.startDate)) {
      throw const InvalidDateRange();
    }

    // RN-04: no permitir traslape con otra reserva vigente del mismo
    // artículo.
    final overlaps = _rentals.values.any(
      (r) =>
          r.listingId == request.listingId &&
          _blockingStates.contains(r.status) &&
          _datesOverlap(
            r.startDate,
            r.endDate,
            request.startDate,
            request.endDate,
          ),
    );
    if (overlaps) throw const DateOverlap();

    final amount = _priceFor(request);
    final rental = Rental(
      id: _nextId(),
      listingId: request.listingId,
      listingTitle: _titleFor(request.listingId),
      renterId: renterId,
      renterName: renterName,
      ownerId: 'u-demo',
      ownerName: 'Usuario Demo',
      period: request.period,
      startDate: request.startDate,
      endDate: request.endDate,
      amount: amount,
      status: RentalStatus.requested,
    );
    _rentals[rental.id] = rental;
    return rental;
  }

  @override
  Future<Rental> pay({
    required String rentalId,
    bool forceSuccess = true,
  }) async {
    await Future<void>.delayed(_delay);
    final rental = _rentals[rentalId];
    if (rental == null) {
      throw const InvalidRentalTransition('La renta no existe');
    }
    if (!rental.canPay) {
      throw const InvalidRentalTransition(
        'La renta no está en un estado pagable',
      );
    }
    if (!forceSuccess) {
      // El pago falla: la renta permanece en SOLICITADA para reintentar.
      throw const PaymentFailed();
    }

    final payment = Payment(
      reference: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      amount: rental.amount,
      paidAt: DateTime.now(),
    );
    // PAGADA → CONFIRMADA, y se genera el boleto con QR (HU-15).
    final ticket = _generateTicket(rental);
    final confirmed = rental.copyWith(
      status: RentalStatus.confirmed,
      payment: payment,
      ticket: ticket,
    );
    _rentals[rentalId] = confirmed;
    return confirmed;
  }

  @override
  Future<Rental> cancel({required String rentalId}) async {
    await Future<void>.delayed(_delay);
    final rental = _rentals[rentalId];
    if (rental == null) {
      throw const InvalidRentalTransition('La renta no existe');
    }
    if (!rental.canCancel) {
      throw const InvalidRentalTransition(
        'Solo puedes cancelar una solicitud no pagada',
      );
    }
    final cancelled = rental.copyWith(status: RentalStatus.cancelled);
    _rentals[rentalId] = cancelled;
    return cancelled;
  }

  @override
  Future<List<Rental>> listForRenter(String renterId) async {
    await Future<void>.delayed(_delay);
    return _rentals.values.where((r) => r.renterId == renterId).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  @override
  Future<List<Rental>> listForSeller(String ownerId) async {
    await Future<void>.delayed(_delay);
    return _rentals.values.where((r) => r.ownerId == ownerId).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  @override
  Future<Rental?> findById(String rentalId) async {
    await Future<void>.delayed(_delay);
    return _rentals[rentalId];
  }

  // --- Recepción (Épica 4) ---------------------------------------------

  @override
  Future<Rental?> findByQrToken(String token) async {
    await Future<void>.delayed(_delay);
    for (final rental in _rentals.values) {
      if (rental.ticket?.token == token) return rental;
    }
    return null;
  }

  @override
  Future<Rental> receiveFromSeller({
    required String rentalId,
    required String itemCondition,
    required String receivedBy,
  }) async {
    await Future<void>.delayed(_delay);
    final rental = _rentals[rentalId];
    if (rental == null) {
      throw const InvalidRentalTransition('La renta no existe');
    }
    if (rental.status != RentalStatus.confirmed) {
      throw const InvalidRentalTransition(
        'La renta debe estar confirmada para recibirse',
      );
    }
    final updated = rental.copyWith(
      status: RentalStatus.inReception,
      itemConditionNote: itemCondition,
      receivedBy: receivedBy,
    );
    _rentals[rentalId] = updated;
    return updated;
  }

  @override
  Future<Rental> deliverToRenter({required String rentalId}) async {
    await Future<void>.delayed(_delay);
    final rental = _rentals[rentalId];
    if (rental == null) {
      throw const InvalidRentalTransition('La renta no existe');
    }
    // RN-05: sin un QR válido en la fase de entrega no se entrega.
    final ticket = rental.ticket;
    if (ticket == null || !ticket.isValidAt(DateTime.now())) {
      throw const InvalidRentalTransition(
        'Se requiere un QR válido para entregar el artículo',
      );
    }
    if (rental.status != RentalStatus.inReception) {
      throw const InvalidRentalTransition(
        'El artículo debe estar en recepción para entregarse',
      );
    }
    // ENTREGADA → EN RENTA, e invalida el QR usado (HU-17).
    final updated = rental.copyWith(
      status: RentalStatus.onRent,
      ticket: ticket.copyWith(used: true),
    );
    _rentals[rentalId] = updated;
    return updated;
  }

  @override
  Future<Rental> registerReturn({
    required String rentalId,
    required String itemCondition,
  }) async {
    await Future<void>.delayed(_delay);
    final rental = _rentals[rentalId];
    if (rental == null) {
      throw const InvalidRentalTransition('La renta no existe');
    }
    if (rental.status != RentalStatus.onRent) {
      throw const InvalidRentalTransition(
        'La renta debe estar en curso para registrar la devolución',
      );
    }
    // DEVUELTA → FINALIZADA (retorno al vendedor).
    final updated = rental.copyWith(
      status: RentalStatus.finished,
      itemConditionNote: itemCondition,
    );
    _rentals[rentalId] = updated;
    return updated;
  }

  @override
  Future<Rental> markIncidence({required String rentalId}) async {
    await Future<void>.delayed(_delay);
    final rental = _rentals[rentalId];
    if (rental == null) {
      throw const InvalidRentalTransition('La renta no existe');
    }
    final updated = rental.copyWith(status: RentalStatus.incident);
    _rentals[rentalId] = updated;
    return updated;
  }

  /// Genera un boleto con QR único e irrepetible para la fase de entrega.
  QrTicket _generateTicket(Rental rental) {
    final token = 'QR-${rental.id}-${_tokenCounter++}-'
        '${DateTime.now().microsecondsSinceEpoch}';
    // Firma simulada: el backend usaría criptografía real (RNF-05).
    final signature = token.hashCode.toRadixString(16);
    return QrTicket(
      token: token,
      signature: signature,
      phase: QrPhase.pickup,
      issuedAt: DateTime.now(),
      // Vigencia hasta el fin del lapso de renta.
      expiresAt: rental.endDate,
    );
  }

  bool _datesOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    // Hay traslape si cada inicio es anterior al fin del otro.
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  double _priceFor(RentalRequest request) {
    final duration = request.endDate.difference(request.startDate);
    // Tarifas base de ejemplo por periodo (el backend usaría el precio real
    // de la publicación).
    return switch (request.period) {
      RentalPeriod.hour => 30.0 * duration.inHours.clamp(1, 1000),
      RentalPeriod.day => 25.0 * duration.inDays.clamp(1, 1000),
      RentalPeriod.week =>
        120.0 * (duration.inDays / 7).ceil().clamp(1, 1000),
    };
  }

  String _titleFor(String listingId) => 'Artículo $listingId';
}
