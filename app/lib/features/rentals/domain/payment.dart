/// Registro de un pago de renta (HU-14).
///
/// Cada pago queda con fecha, monto y referencia. En el mock la referencia
/// es un folio generado localmente; con backend vendría de la pasarela.
class Payment {
  const Payment({
    required this.reference,
    required this.amount,
    required this.paidAt,
  });

  /// Folio/referencia del pago.
  final String reference;

  /// Monto cobrado en MXN.
  final double amount;

  final DateTime paidAt;
}
