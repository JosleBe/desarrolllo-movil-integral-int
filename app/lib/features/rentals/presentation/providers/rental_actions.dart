import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/rental.dart';
import '../../domain/rental_repository.dart';
import 'rentals_providers.dart';

/// Orquesta las acciones del Rentador sobre sus rentas (HU-13/14/16).
/// Tras cada acción invalida los listados para refrescar la UI.
final rentalActionsProvider = Provider<RentalActions>(RentalActions.new);

class RentalActions {
  RentalActions(this._ref);

  final Ref _ref;

  RentalRepository get _repo => _ref.read(rentalRepositoryProvider);

  void _refresh() {
    _ref.invalidate(myRentalsProvider);
    _ref.invalidate(sellerRentalsProvider);
  }

  /// Solicita una renta (HU-13). Puede lanzar [DateOverlap] /
  /// [InvalidDateRange].
  Future<Rental> request(RentalRequest request) async {
    final user = _ref.read(authControllerProvider).user!;
    final rental = await _repo.request(
      renterId: user.id,
      renterName: user.fullName,
      request: request,
    );
    _refresh();
    return rental;
  }

  /// Paga una renta (HU-14). [forceSuccess] false simula un fallo para
  /// probar el reintento. Puede lanzar [PaymentFailed].
  Future<Rental> pay(String rentalId, {bool forceSuccess = true}) async {
    final rental = await _repo.pay(
      rentalId: rentalId,
      forceSuccess: forceSuccess,
    );
    _refresh();
    _ref.invalidate(rentalDetailProvider(rentalId));
    return rental;
  }

  /// Cancela una renta en SOLICITADA (HU-16).
  Future<Rental> cancel(String rentalId) async {
    final rental = await _repo.cancel(rentalId: rentalId);
    _refresh();
    _ref.invalidate(rentalDetailProvider(rentalId));
    return rental;
  }
}
