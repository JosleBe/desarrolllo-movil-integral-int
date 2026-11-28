import '../../catalog/domain/catalog_enums.dart';
import '../domain/earnings_period.dart';
import '../domain/notification_service.dart';
import '../domain/payment.dart';
import '../domain/qr_ticket.dart';
import '../domain/rental.dart';
import '../domain/rental_repository.dart';
import '../domain/rental_status.dart';
import '../domain/seller_earnings.dart';

/// Implementación en memoria de [RentalRepository] para trabajar sin backend.
class MockRentalRepository implements RentalRepository {
  MockRentalRepository({NotificationService? notificationService})
      : _notificationService =
            notificationService ?? const MockNotificationService() {
    _seed();
  }

  static const _delay = Duration(milliseconds: 400);
  final NotificationService _notificationService;

  /// Estados que ocupan el artículo y por tanto cuentan para el traslape.
  static const _blockingStates = {
    RentalStatus.pendingApproval,
    RentalStatus.approved,
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
    // 1. Renta en curso
    final paidAt1 = now.subtract(const Duration(days: 2));
    final r1 = Rental(
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
      payment: Payment(
        reference: 'PAY-DEMO-001',
        amount: 75,
        paidAt: paidAt1,
      ),
    );
    _rentals[r1.id] = r1;

    // 2. Renta CONFIRMADA con boleto QR válido
    final paidAt2 = now.subtract(const Duration(hours: 5));
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
      payment: Payment(
        reference: 'PAY-DEMO-002',
        amount: 120,
        paidAt: paidAt2,
      ),
    );
    final ticket = _generateTicket(confirmed);
    _rentals[confirmed.id] = confirmed.copyWith(ticket: ticket);
    seedPickupPayload = ticket.payload;

    // 3. Renta en PENDIENTE_APROBACION para probar HU-38
    final pending = Rental(
      id: _nextId(),
      listingId: 'l-1',
      listingTitle: 'Bata de laboratorio',
      renterId: 'u-demo',
      renterName: 'Usuario Demo',
      ownerId: 'u-laura',
      ownerName: 'Laura P.',
      period: RentalPeriod.day,
      startDate: now.add(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 2)),
      amount: 40,
      status: RentalStatus.pendingApproval,
    );
    _rentals[pending.id] = pending;
  }

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
      status: RentalStatus.pendingApproval,
    );
    _rentals[rental.id] = rental;
    return rental;
  }

  @override
  Future<Rental> approve({required String rentalId}) async {
    await Future<void>.delayed(_delay);
    final rental = _rentals[rentalId];
    if (rental == null) {
      throw const InvalidRentalTransition('La renta no existe');
    }
    if (rental.status != RentalStatus.pendingApproval &&
        rental.status != RentalStatus.requested) {
      throw const InvalidRentalTransition(
        'Solo se pueden aprobar solicitudes pendientes',
      );
    }
    final approved = rental.copyWith(status: RentalStatus.approved);
    _rentals[rentalId] = approved;
    await _notificationService.notifyRenterOnStatusChange(
      rental: approved,
      message: 'Tu solicitud para "${approved.listingTitle}" fue aprobada. Ya puedes realizar el pago.',
    );
    return approved;
  }

  @override
  Future<Rental> reject({required String rentalId, String? reason}) async {
    await Future<void>.delayed(_delay);
    final rental = _rentals[rentalId];
    if (rental == null) {
      throw const InvalidRentalTransition('La renta no existe');
    }
    if (rental.status != RentalStatus.pendingApproval &&
        rental.status != RentalStatus.requested) {
      throw const InvalidRentalTransition(
        'Solo se pueden rechazar solicitudes pendientes',
      );
    }
    final rejected = rental.copyWith(
      status: RentalStatus.rejected,
      rejectionReason: reason,
    );
    _rentals[rentalId] = rejected;
    await _notificationService.notifyRenterOnStatusChange(
      rental: rejected,
      message: 'Tu solicitud para "${rejected.listingTitle}" fue rechazada'
          '${reason != null && reason.isNotEmpty ? ": $reason" : "."}',
    );
    return rejected;
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
        'La solicitud debe ser aprobada por el Vendedor antes del pago',
      );
    }
    if (!forceSuccess) {
      throw const PaymentFailed();
    }

    final payment = Payment(
      reference: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      amount: rental.amount,
      paidAt: DateTime.now(),
    );
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
  Future<List<Rental>> listPaymentHistory(String renterId) async {
    await Future<void>.delayed(_delay);
    return _rentals.values
        .where((r) => r.renterId == renterId && r.payment != null)
        .toList()
      ..sort((a, b) => b.payment!.paidAt.compareTo(a.payment!.paidAt));
  }

  @override
  Future<List<Rental>> listForSeller(String ownerId) async {
    await Future<void>.delayed(_delay);
    return _rentals.values.where((r) => r.ownerId == ownerId).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  @override
  Future<SellerEarnings> getSellerEarnings({
    required String ownerId,
    EarningsPeriod period = EarningsPeriod.all,
    String? listingId,
  }) async {
    await Future<void>.delayed(_delay);

    final now = DateTime.now();
    DateTime? startDateLimit;
    switch (period) {
      case EarningsPeriod.week:
        startDateLimit = now.subtract(const Duration(days: 7));
        break;
      case EarningsPeriod.month:
        startDateLimit = now.subtract(const Duration(days: 30));
        break;
      case EarningsPeriod.year:
        startDateLimit = now.subtract(const Duration(days: 365));
        break;
      case EarningsPeriod.all:
        startDateLimit = null;
        break;
    }

    final sellerPaidRentals = _rentals.values.where((r) {
      if (r.ownerId != ownerId || r.payment == null) return false;
      if (listingId != null && listingId.isNotEmpty && r.listingId != listingId) {
        return false;
      }
      if (startDateLimit != null && r.payment!.paidAt.isBefore(startDateLimit)) {
        return false;
      }
      return true;
    }).toList();

    double totalEarnings = 0.0;
    final Map<String, ListingEarningsBuilder> byListingMap = {};
    final List<EarningsDataPoint> chartPoints = [];

    for (final r in sellerPaidRentals) {
      final amount = r.payment!.amount;
      totalEarnings += amount;

      final builder = byListingMap.putIfAbsent(
        r.listingId,
        () => ListingEarningsBuilder(r.listingId, r.listingTitle),
      );
      builder.totalAmount += amount;
      builder.count += 1;

      chartPoints.add(
        EarningsDataPoint(
          label: '${r.payment!.paidAt.day}/${r.payment!.paidAt.month}',
          amount: amount,
          date: r.payment!.paidAt,
        ),
      );
    }

    chartPoints.sort((a, b) => a.date.compareTo(b.date));

    final byListingList = byListingMap.values
        .map((b) => ListingEarnings(
              listingId: b.listingId,
              listingTitle: b.listingTitle,
              totalAmount: b.totalAmount,
              completedRentalsCount: b.count,
            ))
        .toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return SellerEarnings(
      ownerId: ownerId,
      period: period,
      totalEarnings: totalEarnings,
      totalRentalsCount: sellerPaidRentals.length,
      byListing: byListingList,
      chartPoints: chartPoints,
      selectedListingId: listingId,
    );
  }

  @override
  Future<Rental?> findById(String rentalId) async {
    await Future<void>.delayed(_delay);
    return _rentals[rentalId];
  }

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

  QrTicket _generateTicket(Rental rental) {
    final token = 'QR-${rental.id}-${_tokenCounter++}-'
        '${DateTime.now().microsecondsSinceEpoch}';
    final signature = token.hashCode.toRadixString(16);
    return QrTicket(
      token: token,
      signature: signature,
      phase: QrPhase.pickup,
      issuedAt: DateTime.now(),
      expiresAt: rental.endDate,
    );
  }

  bool _datesOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  double _priceFor(RentalRequest request) {
    final duration = request.endDate.difference(request.startDate);
    return switch (request.period) {
      RentalPeriod.hour => 30.0 * duration.inHours.clamp(1, 1000),
      RentalPeriod.day => 25.0 * duration.inDays.clamp(1, 1000),
      RentalPeriod.week => 120.0 * (duration.inDays / 7).ceil().clamp(1, 1000),
    };
  }

  String _titleFor(String listingId) => 'Artículo $listingId';
}

class ListingEarningsBuilder {
  ListingEarningsBuilder(this.listingId, this.listingTitle);
  final String listingId;
  final String listingTitle;
  double totalAmount = 0.0;
  int count = 0;
}
