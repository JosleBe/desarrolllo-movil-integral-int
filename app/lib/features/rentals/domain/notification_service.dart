import 'rental.dart';

/// Interfaz del servicio de avisos/notificaciones (HU-38, desacoplamiento de HU-52).
abstract interface class NotificationService {
  /// Envía un aviso al rentador informando del cambio de estado de su solicitud.
  Future<void> notifyRenterOnStatusChange({
    required Rental rental,
    required String message,
  });
}

/// Implementación mock / logger seguro para desarrollo mientras HU-52 no está lista.
class MockNotificationService implements NotificationService {
  const MockNotificationService();

  @override
  Future<void> notifyRenterOnStatusChange({
    required Rental rental,
    required String message,
  }) async {
    // Log seguro sin revelar tokens ni datos sensibles.
    // Usado como puente hacia la tabla de avisos de HU-52.
  }
}
