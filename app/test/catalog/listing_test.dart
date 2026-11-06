import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/catalog/domain/catalog_enums.dart';
import 'package:sruu/features/catalog/domain/listing.dart';

void main() {
  group('modelo Listing', () {
    const base = Listing(
      id: 'l-1',
      ownerId: 'u-1',
      ownerName: 'Dueño',
      title: 'Calculadora',
      description: 'desc',
      category: Category.calculator,
      condition: ItemCondition.good,
      prices: [
        PriceOption(period: RentalPeriod.day, amount: 25),
        PriceOption(period: RentalPeriod.week, amount: 120),
      ],
    );

    test('lowestPrice toma el precio más bajo entre periodos', () {
      expect(base.lowestPrice, 25);
    });

    test('isRentable requiere activa y disponible', () {
      expect(base.isRentable, isTrue);
      expect(base.copyWith(available: false).isRentable, isFalse);
      expect(
        base.copyWith(status: ListingStatus.paused).isRentable,
        isFalse,
      );
    });

    test('hasActiveRentals marca la publicación como no borrable', () {
      final conRentas = base.copyWith(hasActiveRentals: true);
      expect(conRentas.hasActiveRentals, isTrue);
    });
  });
}
