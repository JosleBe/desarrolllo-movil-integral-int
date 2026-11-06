/// Estados del ciclo de vida de una renta (DFR sección 9).
///
/// Flujo normal:
/// SOLICITADA → PAGADA → CONFIRMADA → EN RECEPCIÓN → ENTREGADA →
/// EN RENTA → DEVUELTA → FINALIZADA
///
/// Excepcionales: CANCELADA, RECHAZADA, INCIDENCIA.
enum RentalStatus {
  requested('Solicitada'),
  paid('Pagada'),
  confirmed('Confirmada'),
  inReception('En recepción'),
  delivered('Entregada'),
  onRent('En renta'),
  returned('Devuelta'),
  finished('Finalizada'),
  cancelled('Cancelada'),
  rejected('Rechazada'),
  incident('Incidencia');

  const RentalStatus(this.label);

  final String label;
}
