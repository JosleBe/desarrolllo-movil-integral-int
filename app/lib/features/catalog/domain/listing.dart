import 'catalog_enums.dart';

/// Publicación de un útil en renta (RF-05, HU-06 a HU-11).
///
/// Modelo de dominio puro: no conoce JSON ni HTTP. Reúne los datos que el
/// Vendedor define (nombre, descripción, categoría, estado, precios,
/// imágenes) más el estado de la publicación y su disponibilidad.
class Listing {
  const Listing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.prices,
    this.imageUrls = const [],
    this.status = ListingStatus.active,
    this.available = true,
    this.hasActiveRentals = false,
  });

  final String id;

  /// Id del Vendedor dueño de la publicación (para HU-07: solo el dueño
  /// puede modificarla).
  final String ownerId;
  final String ownerName;

  final String title;
  final String description;
  final Category category;
  final ItemCondition condition;

  /// Precios por periodo (HU-08). Al menos uno.
  final List<PriceOption> prices;

  /// URLs de imágenes (HU-09). En el mock son placeholders; la subida real
  /// a Cloud (RNF-06) la hará el backend.
  final List<String> imageUrls;

  final ListingStatus status;

  /// Disponibilidad actual (HU-11). En el mock es un valor fijo; con backend
  /// se calcularía por rango de fechas y se actualizaría en tiempo real.
  final bool available;

  /// Indica si tiene rentas activas o pendientes. Bloquea la eliminación
  /// (HU-07, RN-04).
  final bool hasActiveRentals;

  bool get isActive => status == ListingStatus.active;

  /// Rentable solo si está activa y disponible.
  bool get isRentable => isActive && available;

  /// Precio más bajo entre los periodos, útil para mostrar "desde $X".
  double get lowestPrice =>
      prices.map((p) => p.amount).reduce((a, b) => a < b ? a : b);

  Listing copyWith({
    String? title,
    String? description,
    Category? category,
    ItemCondition? condition,
    List<PriceOption>? prices,
    List<String>? imageUrls,
    ListingStatus? status,
    bool? available,
    bool? hasActiveRentals,
  }) {
    return Listing(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      prices: prices ?? this.prices,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      available: available ?? this.available,
      hasActiveRentals: hasActiveRentals ?? this.hasActiveRentals,
    );
  }

  @override
  bool operator ==(Object other) => other is Listing && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
