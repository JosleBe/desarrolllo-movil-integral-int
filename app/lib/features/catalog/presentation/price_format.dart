import '../domain/catalog_enums.dart';
import '../domain/listing.dart';

/// Utilidades de formato para mostrar precios y periodos en la UI.
abstract final class PriceFormat {
  /// Formatea un monto como pesos mexicanos: `$25` o `$1,200`.
  static String money(double amount) {
    final rounded = amount.round();
    final text = rounded.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return '\$$buffer';
  }

  /// Etiqueta corta de periodo: "hora", "día", "semana".
  static String periodUnit(RentalPeriod period) => switch (period) {
    RentalPeriod.hour => 'hora',
    RentalPeriod.day => 'día',
    RentalPeriod.week => 'semana',
  };

  /// "$25 / día".
  static String option(PriceOption option) =>
      '${money(option.amount)} / ${periodUnit(option.period)}';

  /// "Desde $25 / día" usando el precio más bajo de la publicación.
  static String lowestLabel(Listing listing) {
    final cheapest = listing.prices.reduce(
      (a, b) => a.amount < b.amount ? a : b,
    );
    return 'Desde ${option(cheapest)}';
  }
}
