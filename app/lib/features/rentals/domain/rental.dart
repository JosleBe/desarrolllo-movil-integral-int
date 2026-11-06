import '../../catalog/domain/catalog_enums.dart';
import 'payment.dart';
import 'qr_ticket.dart';
import 'rental_status.dart';

/// Renta de un artículo a lo largo de su ciclo de vida (Épica 3).
///
/// Modelo de dominio puro. Reúne el artículo rentado, las partes
/// (rentador y vendedor), el periodo/fechas, el monto, y —según avanza el
/// flujo— el pago (HU-14) y el boleto con QR (HU-15).
class Rental {
  const Rental({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.renterId,
    required this.renterName,
    required this.ownerId,
    required this.ownerName,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.status,
    this.payment,
    this.ticket,
    this.itemConditionNote,
    this.receivedBy,
  });

  final String id;

  final String listingId;
  final String listingTitle;

  final String renterId;
  final String renterName;

  final String ownerId;
  final String ownerName;

  /// Periodo de renta elegido (hora/día/semana) y fechas del lapso.
  final RentalPeriod period;
  final DateTime startDate;
  final DateTime endDate;

  /// Monto total de la renta en MXN.
  final double amount;

  final RentalStatus status;

  /// Pago asociado, presente desde el estado PAGADA (HU-14).
  final Payment? payment;

  /// Boleto con QR, presente tras CONFIRMADA (HU-15).
  final QrTicket? ticket;

  /// Estado del artículo anotado en Recepción (HU-19/21).
  final String? itemConditionNote;

  /// Responsable que registró la recepción (HU-19).
  final String? receivedBy;

  bool get isRequested => status == RentalStatus.requested;
  bool get isConfirmed => status == RentalStatus.confirmed;

  /// Se puede cancelar solo mientras no se haya pagado (HU-16).
  bool get canCancel => status == RentalStatus.requested;

  /// Se puede pagar solo si está en SOLICITADA (HU-14).
  bool get canPay => status == RentalStatus.requested;

  Rental copyWith({
    RentalStatus? status,
    Payment? payment,
    QrTicket? ticket,
    String? itemConditionNote,
    String? receivedBy,
  }) {
    return Rental(
      id: id,
      listingId: listingId,
      listingTitle: listingTitle,
      renterId: renterId,
      renterName: renterName,
      ownerId: ownerId,
      ownerName: ownerName,
      period: period,
      startDate: startDate,
      endDate: endDate,
      amount: amount,
      status: status ?? this.status,
      payment: payment ?? this.payment,
      ticket: ticket ?? this.ticket,
      itemConditionNote: itemConditionNote ?? this.itemConditionNote,
      receivedBy: receivedBy ?? this.receivedBy,
    );
  }
}
