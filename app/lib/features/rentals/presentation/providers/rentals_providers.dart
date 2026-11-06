import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/mock_rental_repository.dart';
import '../../domain/rental.dart';
import '../../domain/rental_repository.dart';
import '../../domain/rental_status.dart';

/// Repositorio de rentas (singleton en memoria).
///
/// Sustituible por una implementación con Dio cuando exista el backend,
/// sin tocar la UI ni los controladores.
final rentalRepositoryProvider = Provider<RentalRepository>(
  (ref) => MockRentalRepository(),
);

// ---------------------------------------------------------------------------
// Listados
// ---------------------------------------------------------------------------

/// Rentas del Rentador autenticado (HU-13 a HU-16).
final myRentalsProvider = FutureProvider<List<Rental>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return Future.value(const []);
  return ref.watch(rentalRepositoryProvider).listForRenter(user.id);
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

/// Rentas de los artículos del Vendedor, filtradas por estado (HU-12).
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

/// Detalle de una renta por id.
final rentalDetailProvider = FutureProvider.family<Rental?, String>((
  ref,
  id,
) {
  return ref.watch(rentalRepositoryProvider).findById(id);
});
