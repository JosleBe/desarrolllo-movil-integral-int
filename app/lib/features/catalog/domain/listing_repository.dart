import 'catalog_enums.dart';
import 'catalog_filters.dart';
import 'listing.dart';

/// Errores de dominio del catálogo.
sealed class CatalogException implements Exception {
  const CatalogException(this.message);
  final String message;
  @override
  String toString() => 'CatalogException: $message';
}

/// Se intentó eliminar una publicación con rentas activas o pendientes
/// (HU-07, RN-04).
class ListingHasActiveRentals extends CatalogException {
  const ListingHasActiveRentals()
    : super('No puedes eliminar una publicación con rentas activas');
}

/// Se intentó modificar una publicación que no pertenece al usuario (HU-07).
class NotListingOwner extends CatalogException {
  const NotListingOwner()
    : super('Solo puedes modificar tus propias publicaciones');
}

/// Datos de entrada para crear o editar una publicación (HU-06, HU-08).
class ListingDraft {
  const ListingDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.prices,
    this.imageUrls = const [],
  });

  final String title;
  final String description;
  final Category category;
  final ItemCondition condition;
  final List<PriceOption> prices;
  final List<String> imageUrls;
}

/// Contrato del catálogo (capa domain).
///
/// La presentación depende de esta abstracción. Hoy la cumple un mock en
/// memoria; con backend, una implementación con Dio la reemplazará.
abstract interface class ListingRepository {
  /// Busca publicaciones activas del catálogo aplicando [filters] (HU-10).
  /// Solo devuelve publicaciones en estado activo (las pausadas se ocultan).
  Future<List<Listing>> search(CatalogFilters filters);

  /// Devuelve una publicación por id, o `null` si no existe.
  Future<Listing?> findById(String id);

  /// Publicaciones de un vendedor (panel "Mis publicaciones", HU-07).
  Future<List<Listing>> listByOwner(String ownerId);

  /// Crea una publicación para el vendedor dado (HU-06).
  Future<Listing> create({
    required String ownerId,
    required String ownerName,
    required ListingDraft draft,
  });

  /// Edita una publicación propia (HU-07). Lanza [NotListingOwner] si el
  /// usuario no es el dueño.
  Future<Listing> update({
    required String listingId,
    required String ownerId,
    required ListingDraft draft,
  });

  /// Cambia el estado activa/pausada (HU-07).
  Future<Listing> setStatus({
    required String listingId,
    required String ownerId,
    required ListingStatus status,
  });

  /// Elimina una publicación propia (HU-07). Lanza [ListingHasActiveRentals]
  /// si tiene rentas activas o pendientes (RN-04).
  Future<void> delete({required String listingId, required String ownerId});

  // --- Moderación por el Administrador (HU-27) --------------------------

  /// Lista todas las publicaciones, incluidas las pausadas (moderación).
  Future<List<Listing>> listAll();

  /// Pausa o elimina una publicación como Administrador, con un motivo
  /// (HU-27). No valida propiedad: el Admin puede moderar cualquiera.
  Future<Listing> moderatePause({
    required String listingId,
    required String reason,
  });

  Future<void> moderateRemove({
    required String listingId,
    required String reason,
  });
}
