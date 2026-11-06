import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/catalog/data/mock_listing_repository.dart';
import 'package:sruu/features/catalog/domain/catalog_enums.dart';
import 'package:sruu/features/catalog/domain/catalog_filters.dart';
import 'package:sruu/features/catalog/domain/listing_repository.dart';

void main() {
  late MockListingRepository repo;

  setUp(() => repo = MockListingRepository());

  group('búsqueda con filtros combinables (HU-10)', () {
    test('sin filtros devuelve solo publicaciones activas', () async {
      final results = await repo.search(const CatalogFilters());
      expect(results, hasLength(4));
      expect(results.every((l) => l.isActive), isTrue);
    });

    test('filtra por categoría', () async {
      final results = await repo.search(
        const CatalogFilters(category: Category.calculator),
      );
      expect(results, isNotEmpty);
      expect(
        results.every((l) => l.category == Category.calculator),
        isTrue,
      );
    });

    test('filtra por texto en título/descripción', () async {
      final results = await repo.search(
        const CatalogFilters(query: 'multímetro'),
      );
      expect(results, hasLength(1));
      expect(results.first.category, Category.multimeter);
    });

    test('combina categoría + solo disponibles', () async {
      final results = await repo.search(
        const CatalogFilters(
          category: Category.laptop,
          onlyAvailable: true,
        ),
      );
      expect(results, isEmpty);
    });

    test('filtra por periodo de renta', () async {
      final results = await repo.search(
        const CatalogFilters(period: RentalPeriod.hour),
      );
      expect(
        results.every((l) => l.prices.any((p) => p.period == RentalPeriod.hour)),
        isTrue,
      );
    });

    test('rango de precio por precio más bajo', () async {
      final results = await repo.search(
        const CatalogFilters(maxPrice: 30),
      );
      expect(results, isNotEmpty);
      expect(results.every((l) => l.lowestPrice <= 30), isTrue);
    });

    test('sin coincidencias devuelve lista vacía', () async {
      final results = await repo.search(
        const CatalogFilters(query: 'xyz-no-existe'),
      );
      expect(results, isEmpty);
    });
  });

  group('gestión de publicaciones (HU-06, HU-07)', () {
    const draft = ListingDraft(
      title: 'Regla T',
      description: 'Regla T para dibujo',
      category: Category.drawingKit,
      condition: ItemCondition.good,
      prices: [PriceOption(period: RentalPeriod.day, amount: 15)],
    );

    test('crear agrega la publicación al catálogo del dueño', () async {
      final created = await repo.create(
        ownerId: 'u-demo',
        ownerName: 'Usuario Demo',
        draft: draft,
      );
      final mine = await repo.listByOwner('u-demo');
      expect(mine.any((l) => l.id == created.id), isTrue);
    });

    test('editar publicación ajena lanza NotListingOwner', () async {
      final mine = await repo.listByOwner('u-demo');
      final listing = mine.first;
      expect(
        () => repo.update(
          listingId: listing.id,
          ownerId: 'otro-usuario',
          draft: draft,
        ),
        throwsA(isA<NotListingOwner>()),
      );
    });

    test('pausar oculta la publicación del catálogo (HU-07)', () async {
      final mine = await repo.listByOwner('u-demo');
      final active = mine.firstWhere((l) => l.isActive);
      await repo.setStatus(
        listingId: active.id,
        ownerId: 'u-demo',
        status: ListingStatus.paused,
      );
      final results = await repo.search(const CatalogFilters());
      expect(results.any((l) => l.id == active.id), isFalse);
    });

    test('eliminar quita la publicación', () async {
      final created = await repo.create(
        ownerId: 'u-demo',
        ownerName: 'Usuario Demo',
        draft: draft,
      );
      await repo.delete(listingId: created.id, ownerId: 'u-demo');
      expect(await repo.findById(created.id), isNull);
    });
  });
}
