import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/rental.dart';
import '../../domain/rental_repository.dart';
import 'rentals_providers.dart';

/// Orquesta las acciones del Rentador y Vendedor sobre las rentas (HU-13/14/16/38).
/// Tras cada acción invalida los listados para refrescar la UI.
final rentalActionsProvider = Provider<RentalActions>(RentalActions.new);

class RentalActions {
  RentalActions(this._ref);

  final Ref _ref;

  RentalRepository get _repo => _ref.read(rentalRepositoryProvider);

  void _refresh() {
    _ref.invalidate(myRentalsProvider);
    _ref.invalidate(sellerRentalsProvider);
    _ref.invalidate(paymentHistoryProvider);
    _ref.invalidate(sellerEarningsProvider);
  }

  /// Solicita una renta en PENDIENTE_APROBACION (HU-13, HU-38).
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

  /// Aprueba una solicitud de renta (HU-38).
  Future<Rental> approve(String rentalId) async {
    final rental = await _repo.approve(rentalId: rentalId);
    _refresh();
    _ref.invalidate(rentalDetailProvider(rentalId));
    return rental;
  }

  /// Rechaza una solicitud de renta con motivo opcional (HU-38).
  Future<Rental> reject(String rentalId, {String? reason}) async {
    final rental = await _repo.reject(rentalId: rentalId, reason: reason);
    _refresh();
    _ref.invalidate(rentalDetailProvider(rentalId));
    return rental;
  }

  /// Paga una renta (HU-14, HU-38).
  Future<Rental> pay(String rentalId, {bool forceSuccess = true}) async {
    final rental = await _repo.pay(
      rentalId: rentalId,
      forceSuccess: forceSuccess,
    );
    _refresh();
    _ref.invalidate(rentalDetailProvider(rentalId));
    return rental;
  }

  /// Cancela una renta no pagada (HU-16).
  Future<Rental> cancel(String rentalId) async {
    final rental = await _repo.cancel(rentalId: rentalId);
    _refresh();
    _ref.invalidate(rentalDetailProvider(rentalId));
    return rental;
  }
}
