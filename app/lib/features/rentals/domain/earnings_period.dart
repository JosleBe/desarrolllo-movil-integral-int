/// Periodos de filtrado para el panel de ganancias del Vendedor (HU-37).
enum EarningsPeriod {
  week('Esta semana'),
  month('Este mes'),
  year('Este año'),
  all('Todo el historial');

  const EarningsPeriod(this.label);

  final String label;
}
