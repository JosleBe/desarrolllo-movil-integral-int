import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/catalog_enums.dart';
import '../../domain/listing.dart';
import '../../domain/listing_repository.dart';
import 'catalog_providers.dart';

/// Orquesta las acciones del Vendedor sobre sus publicaciones (HU-06/07).
///
/// Tras cada acción invalida los providers de listado para que el catálogo
/// y "Mis publicaciones" se refresquen.
final listingActionsProvider = Provider<ListingActions>((ref) {
  return ListingActions(ref);
});

class ListingActions {
  ListingActions(this._ref);

  final Ref _ref;

  ListingRepository get _repo => _ref.read(listingRepositoryProvider);

  void _refresh() {
    _ref.invalidate(catalogResultsProvider);
    _ref.invalidate(myListingsProvider);
  }

  /// Crea una publicación para el usuario autenticado (HU-06).
  Future<Listing> create(ListingDraft draft) async {
    final user = _ref.read(authControllerProvider).user!;
    final listing = await _repo.create(
      ownerId: user.id,
      ownerName: user.fullName,
      draft: draft,
    );
    _refresh();
    return listing;
  }

  /// Edita una publicación propia (HU-07).
  Future<Listing> update(String listingId, ListingDraft draft) async {
    final user = _ref.read(authControllerProvider).user!;
    final listing = await _repo.update(
      listingId: listingId,
      ownerId: user.id,
      draft: draft,
    );
    _refresh();
    _ref.invalidate(listingDetailProvider(listingId));
    return listing;
  }

  /// Pausa o reactiva una publicación (HU-07).
  Future<Listing> setStatus(String listingId, ListingStatus status) async {
    final user = _ref.read(authControllerProvider).user!;
    final listing = await _repo.setStatus(
      listingId: listingId,
      ownerId: user.id,
      status: status,
    );
    _refresh();
    return listing;
  }

  /// Elimina una publicación propia (HU-07). Puede lanzar
  /// [ListingHasActiveRentals].
  Future<void> delete(String listingId) async {
    final user = _ref.read(authControllerProvider).user!;
    await _repo.delete(listingId: listingId, ownerId: user.id);
    _refresh();
  }
}
