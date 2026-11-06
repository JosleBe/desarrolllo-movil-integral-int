import 'catalog_enums.dart';

/// Filtros combinables para la búsqueda avanzada del catálogo (HU-10).
///
/// Todos los campos son opcionales; al combinarlos, un artículo debe
/// cumplir TODAS las condiciones activas para aparecer en los resultados.
class CatalogFilters {
  const CatalogFilters({
    this.query = '',
    this.category,
    this.minPrice,
    this.maxPrice,
    this.period,
    this.onlyAvailable = false,
  });

  /// Texto libre que busca en título y descripción.
  final String query;

  /// Categoría exacta, o `null` para todas.
  final Category? category;

  /// Rango de precio (sobre el precio más bajo de cada publicación).
  final double? minPrice;
  final double? maxPrice;

  /// Exige que la publicación ofrezca este periodo de renta.
  final RentalPeriod? period;

  /// Solo artículos disponibles ahora (HU-11).
  final bool onlyAvailable;

  bool get isEmpty =>
      query.trim().isEmpty &&
      category == null &&
      minPrice == null &&
      maxPrice == null &&
      period == null &&
      !onlyAvailable;

  CatalogFilters copyWith({
    String? query,
    Category? category,
    double? minPrice,
    double? maxPrice,
    RentalPeriod? period,
    bool? onlyAvailable,
    bool clearCategory = false,
    bool clearPeriod = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return CatalogFilters(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      period: clearPeriod ? null : (period ?? this.period),
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    );
  }
}
