import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../rentals/presentation/providers/rentals_providers.dart';
import '../../data/qr_validator.dart';
import '../../domain/qr_validation.dart';

/// Validador de QR de Recepción, construido sobre el repositorio de rentas.
final qrValidatorProvider = Provider<QrValidator>((ref) {
  return QrValidator(ref.watch(rentalRepositoryProvider));
});

/// Acciones del módulo de Recepción (HU-18 a HU-21).
final receptionActionsProvider = Provider<ReceptionActions>(
  ReceptionActions.new,
);

class ReceptionActions {
  ReceptionActions(this._ref);

  final Ref _ref;

  /// Valida un payload de QR escaneado para la fase de entrega (HU-18).
  Future<QrValidationResult> validatePickup(String payload) {
    return _ref.read(qrValidatorProvider).validateForPickup(payload);
  }

  /// Registra la recepción del artículo del Vendedor (HU-19).
  Future<void> receive({
    required String rentalId,
    required String itemCondition,
    required String receivedBy,
  }) async {
    await _ref.read(rentalRepositoryProvider).receiveFromSeller(
          rentalId: rentalId,
          itemCondition: itemCondition,
          receivedBy: receivedBy,
        );
    _invalidate(rentalId);
  }

  /// Entrega el artículo al Rentador tras un QR válido (HU-20, RN-05).
  Future<void> deliver({required String rentalId}) async {
    await _ref.read(rentalRepositoryProvider).deliverToRenter(
          rentalId: rentalId,
        );
    _invalidate(rentalId);
  }

  /// Registra la devolución y el retorno al Vendedor (HU-21).
  Future<void> registerReturn({
    required String rentalId,
    required String itemCondition,
  }) async {
    await _ref.read(rentalRepositoryProvider).registerReturn(
          rentalId: rentalId,
          itemCondition: itemCondition,
        );
    _invalidate(rentalId);
  }

  void _invalidate(String rentalId) {
    _ref.invalidate(rentalDetailProvider(rentalId));
    _ref.invalidate(myRentalsProvider);
    _ref.invalidate(sellerRentalsProvider);
  }
}
