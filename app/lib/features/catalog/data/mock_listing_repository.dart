import '../domain/catalog_enums.dart';
import '../domain/catalog_filters.dart';
import '../domain/listing.dart';
import '../domain/listing_repository.dart';

/// Implementación en memoria de [ListingRepository] para trabajar sin
/// backend. Incluye datos de ejemplo y aplica los filtros combinables de
/// HU-10 en el cliente. La disponibilidad (HU-11) es un valor fijo del
/// mock; con backend se calcularía por fechas y se actualizaría en vivo.
class MockListingRepository implements ListingRepository {
  MockListingRepository() {
    _seed();
  }

  static const _delay = Duration(milliseconds: 350);

  final Map<String, Listing> _listings = {};
  int _idCounter = 0;

  void _seed() {
    final samples = <Listing>[
      Listing(
        id: _nextId(),
        ownerId: 'u-demo',
        ownerName: 'Usuario Demo',
        title: 'Calculadora científica Casio fx-991',
        description:
            'Calculadora científica en excelente estado, ideal para '
            'cálculo e ingeniería.',
        category: Category.calculator,
        condition: ItemCondition.asNew,
        prices: const [
          PriceOption(period: RentalPeriod.day, amount: 25),
          PriceOption(period: RentalPeriod.week, amount: 120),
        ],
      ),
      Listing(
        id: _nextId(),
        ownerId: 'u-otro',
        ownerName: 'Laura M.',
        title: 'Estuche de dibujo técnico',
        description:
            'Juego completo de dibujo técnico: escuadras, compás y '
            'transportador.',
        category: Category.drawingKit,
        condition: ItemCondition.good,
        prices: const [PriceOption(period: RentalPeriod.week, amount: 80)],
      ),
      Listing(
        id: _nextId(),
        ownerId: 'u-otro',
        ownerName: 'Laura M.',
        title: 'Laptop Dell para prácticas',
        description: 'Laptop i5, 8GB RAM. Para prácticas y presentaciones.',
        category: Category.laptop,
        condition: ItemCondition.used,
        prices: const [
          PriceOption(period: RentalPeriod.day, amount: 150),
          PriceOption(period: RentalPeriod.hour, amount: 30),
        ],
        available: false,
      ),
      Listing(
        id: _nextId(),
        ownerId: 'u-pedro',
        ownerName: 'Pedro S.',
        title: 'Multímetro digital',
        description: 'Multímetro para prácticas de electrónica y circuitos.',
        category: Category.multimeter,
        condition: ItemCondition.good,
        prices: const [PriceOption(period: RentalPeriod.day, amount: 40)],
      ),
      Listing(
        id: _nextId(),
        ownerId: 'u-demo',
        ownerName: 'Usuario Demo',
        title: 'Libro de Cálculo (Stewart)',
        description: 'Libro de cálculo diferencial e integral, 8va edición.',
        category: Category.book,
        condition: ItemCondition.worn,
        prices: const [PriceOption(period: RentalPeriod.week, amount: 50)],
        status: ListingStatus.paused,
      ),
    ];
    for (final listing in samples) {
      _listings[listing.id] = listing;
    }
  }

  String _nextId() => 'l-${_idCounter++}';

  @override
  Future<List<Listing>> search(CatalogFilters filters) async {
    await Future<void>.delayed(_delay);
    final query = filters.query.trim().toLowerCase();

    return _listings.values.where((listing) {
      // Solo publicaciones activas aparecen en el catálogo (HU-07).
      if (!listing.isActive) return false;

      if (query.isNotEmpty) {
        final matches =
            listing.title.toLowerCase().contains(query) ||
            listing.description.toLowerCase().contains(query);
        if (!matches) return false;
      }

      if (filters.category != null && listing.category != filters.category) {
        return false;
      }

      if (filters.period != null &&
          !listing.prices.any((p) => p.period == filters.period)) {
        return false;
      }

      final price = listing.lowestPrice;
      if (filters.minPrice != null && price < filters.minPrice!) return false;
      if (filters.maxPrice != null && price > filters.maxPrice!) return false;

      if (filters.onlyAvailable && !listing.available) return false;

      return true;
    }).toList()..sort((a, b) => a.title.compareTo(b.title));
  }

  @override
  Future<Listing?> findById(String id) async {
    await Future<void>.delayed(_delay);
    return _listings[id];
  }

  @override
  Future<List<Listing>> listByOwner(String ownerId) async {
    await Future<void>.delayed(_delay);
    return _listings.values.where((l) => l.ownerId == ownerId).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  @override
  Future<Listing> create({
    required String ownerId,
    required String ownerName,
    required ListingDraft draft,
  }) async {
    await Future<void>.delayed(_delay);
    final listing = Listing(
      id: _nextId(),
      ownerId: ownerId,
      ownerName: ownerName,
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: draft.category,
      condition: draft.condition,
      prices: draft.prices,
      imageUrls: draft.imageUrls,
    );
    _listings[listing.id] = listing;
    return listing;
  }

  @override
  Future<Listing> update({
    required String listingId,
    required String ownerId,
    required ListingDraft draft,
  }) async {
    await Future<void>.delayed(_delay);
    final current = _requireOwned(listingId, ownerId);
    final updated = current.copyWith(
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: draft.category,
      condition: draft.condition,
      prices: draft.prices,
      imageUrls: draft.imageUrls,
    );
    _listings[listingId] = updated;
    return updated;
  }

  @override
  Future<Listing> setStatus({
    required String listingId,
    required String ownerId,
    required ListingStatus status,
  }) async {
    await Future<void>.delayed(_delay);
    final current = _requireOwned(listingId, ownerId);
    final updated = current.copyWith(status: status);
    _listings[listingId] = updated;
    return updated;
  }

  @override
  Future<void> delete({
    required String listingId,
    required String ownerId,
  }) async {
    await Future<void>.delayed(_delay);
    final current = _requireOwned(listingId, ownerId);
    if (current.hasActiveRentals) {
      throw const ListingHasActiveRentals();
    }
    _listings.remove(listingId);
  }

  /// Devuelve la publicación verificando que exista y sea del dueño.
  Listing _requireOwned(String listingId, String ownerId) {
    final listing = _listings[listingId];
    if (listing == null || listing.ownerId != ownerId) {
      throw const NotListingOwner();
    }
    return listing;
  }

  // --- Moderación por el Administrador (HU-27) --------------------------

  @override
  Future<List<Listing>> listAll() async {
    await Future<void>.delayed(_delay);
    return _listings.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  @override
  Future<Listing> moderatePause({
    required String listingId,
    required String reason,
  }) async {
    await Future<void>.delayed(_delay);
    final current = _listings[listingId];
    if (current == null) throw const NotListingOwner();
    final updated = current.copyWith(status: ListingStatus.paused);
    _listings[listingId] = updated;
    return updated;
  }

  @override
  Future<void> moderateRemove({
    required String listingId,
    required String reason,
  }) async {
    await Future<void>.delayed(_delay);
    _listings.remove(listingId);
  }
}
