import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/mock_rental_repository.dart';
import '../../domain/earnings_period.dart';
import '../../domain/rental.dart';
import '../../domain/rental_repository.dart';
import '../../domain/rental_status.dart';
import '../../domain/seller_earnings.dart';

/// Repositorio de rentas (singleton en memoria).
final rentalRepositoryProvider = Provider<RentalRepository>(
  (ref) => MockRentalRepository(),
);

// ---------------------------------------------------------------------------
// Listados
// ---------------------------------------------------------------------------

/// Rentas del Rentador autenticado (HU-13 a HU-16, HU-38).
final myRentalsProvider = FutureProvider<List<Rental>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return Future.value(const []);
  return ref.watch(rentalRepositoryProvider).listForRenter(user.id);
});

/// Historial de pagos del Rentador autenticado (HU-36).
final paymentHistoryProvider = FutureProvider<List<Rental>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return Future.value(const []);
  return ref.watch(rentalRepositoryProvider).listPaymentHistory(user.id);
});

/// Estado seleccionado en el filtro de rentas del vendedor (null = todos).
final rentalFilterProvider =
    NotifierProvider<RentalFilterController, RentalStatus?>(
      RentalFilterController.new,
    );

class RentalFilterController extends Notifier<RentalStatus?> {
  @override
  RentalStatus? build() => null;

  void set(RentalStatus? status) => state = status;
}

/// Rentas de los artículos del Vendedor, filtradas por estado (HU-12, HU-38).
final sellerRentalsProvider = FutureProvider<List<Rental>>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return const [];
  final filter = ref.watch(rentalFilterProvider);
  final all = await ref.watch(rentalRepositoryProvider).listForSeller(
        user.id,
      );
  if (filter == null) return all;
  return all.where((r) => r.status == filter).toList();
});

/// Periodo seleccionado en el filtro de ganancias del vendedor (HU-37).
final sellerEarningsPeriodFilterProvider =
    NotifierProvider<SellerEarningsPeriodController, EarningsPeriod>(
  SellerEarningsPeriodController.new,
);

class SellerEarningsPeriodController extends Notifier<EarningsPeriod> {
  @override
  EarningsPeriod build() => EarningsPeriod.all;

  void set(EarningsPeriod period) => state = period;
}

/// Artículo seleccionado en el filtro de ganancias del vendedor (null = todos) (HU-37).
final sellerEarningsListingFilterProvider =
    NotifierProvider<SellerEarningsListingController, String?>(
  SellerEarningsListingController.new,
);

class SellerEarningsListingController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? listingId) => state = listingId;
}

/// Ganancias agregadas del Vendedor (HU-37).
final sellerEarningsProvider = FutureProvider<SellerEarnings>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) {
    return const SellerEarnings(
      ownerId: '',
      period: EarningsPeriod.all,
      totalEarnings: 0,
      totalRentalsCount: 0,
      byListing: [],
      chartPoints: [],
    );
  }
  final period = ref.watch(sellerEarningsPeriodFilterProvider);
  final listingId = ref.watch(sellerEarningsListingFilterProvider);

  return ref.watch(rentalRepositoryProvider).getSellerEarnings(
        ownerId: user.id,
        period: period,
        listingId: listingId,
      );
});

/// Detalle de una renta por id.
final rentalDetailProvider = FutureProvider.family<Rental?, String>((
  ref,
  id,
) {
  return ref.watch(rentalRepositoryProvider).findById(id);
});
