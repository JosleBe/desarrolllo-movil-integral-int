import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/mock_listing_repository.dart';
import '../../domain/catalog_enums.dart';
import '../../domain/catalog_filters.dart';
import '../../domain/listing.dart';
import '../../domain/listing_repository.dart';

/// Repositorio del catálogo (singleton en memoria).
///
/// Cuando exista el backend, basta cambiar esta línea por la
/// implementación con Dio sin tocar la UI ni los controladores.
final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => MockListingRepository(),
);

/// Filtros activos de la búsqueda del catálogo (HU-10).
final catalogFiltersProvider =
    NotifierProvider<CatalogFiltersController, CatalogFilters>(
      CatalogFiltersController.new,
    );

class CatalogFiltersController extends Notifier<CatalogFilters> {
  @override
  CatalogFilters build() => const CatalogFilters();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setCategory(Category? category) => category == null
      ? state = state.copyWith(clearCategory: true)
      : state = state.copyWith(category: category);

  void setPeriod(RentalPeriod? period) => period == null
      ? state = state.copyWith(clearPeriod: true)
      : state = state.copyWith(period: period);

  void setPriceRange({double? min, double? max}) {
    state = state.copyWith(
      minPrice: min,
      maxPrice: max,
      clearMinPrice: min == null,
      clearMaxPrice: max == null,
    );
  }

  void setOnlyAvailable(bool value) =>
      state = state.copyWith(onlyAvailable: value);

  void clear() => state = const CatalogFilters();
}

/// Resultado de la búsqueda del catálogo según los filtros activos (HU-10).
///
/// Se recalcula automáticamente cuando cambian los filtros.
final catalogResultsProvider = FutureProvider<List<Listing>>((ref) {
  final filters = ref.watch(catalogFiltersProvider);
  final repository = ref.watch(listingRepositoryProvider);
  return repository.search(filters);
});

/// Detalle de una publicación por id.
final listingDetailProvider = FutureProvider.family<Listing?, String>((
  ref,
  id,
) {
  return ref.watch(listingRepositoryProvider).findById(id);
});

/// Publicaciones del usuario autenticado (panel "Mis publicaciones", HU-07).
final myListingsProvider = FutureProvider<List<Listing>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return Future.value(const []);
  return ref.watch(listingRepositoryProvider).listByOwner(user.id);
});
