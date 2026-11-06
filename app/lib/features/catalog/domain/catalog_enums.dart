/// Categoría de un útil académico (RF-05, HU-06).
enum Category {
  calculator('Calculadora'),
  drawingKit('Estuche de dibujo'),
  laptop('Laptop'),
  multimeter('Multímetro'),
  book('Libro'),
  other('Otro');

  const Category(this.label);

  /// Nombre legible para mostrar en la interfaz.
  final String label;
}

/// Estado físico declarado del artículo (HU-06).
enum ItemCondition {
  asNew('Como nuevo'),
  good('Buen estado'),
  used('Usado'),
  worn('Con desgaste');

  const ItemCondition(this.label);

  final String label;
}

/// Unidad de periodo de renta (HU-08: por hora, día o semana).
enum RentalPeriod {
  hour('Por hora'),
  day('Por día'),
  week('Por semana');

  const RentalPeriod(this.label);

  final String label;
}

/// Estado de la publicación en el catálogo (HU-07).
enum ListingStatus {
  /// Visible y rentable en el catálogo.
  active('Activa'),

  /// Oculta del catálogo; no aparece como rentable.
  paused('Pausada');

  const ListingStatus(this.label);

  final String label;
}

/// Precio para un periodo de renta concreto (HU-08).
///
/// Una publicación puede tener uno o más de estos (por hora, día, semana),
/// y se muestran al Rentador antes de solicitar la renta.
class PriceOption {
  const PriceOption({required this.period, required this.amount});

  final RentalPeriod period;

  /// Monto en pesos mexicanos (MXN) para el periodo indicado.
  final double amount;

  @override
  bool operator ==(Object other) =>
      other is PriceOption &&
      other.period == period &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(period, amount);
}
