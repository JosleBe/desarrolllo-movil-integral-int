/// Fase de la transacción en la que un QR es válido (RN-06, HU-17).
///
/// En el flujo del DFR el boleto se usa en Recepción para la entrega
/// (pickup) y luego para la devolución (returnItem). Cada fase consume su
/// propio QR.
enum QrPhase {
  pickup('Entrega'),
  returnItem('Devolución');

  const QrPhase(this.label);
  final String label;
}

/// Estado de vigencia de un QR (HU-17).
enum QrState {
  /// Válido y sin usar.
  valid('Vigente'),

  /// Ya se procesó en su fase: no puede reutilizarse.
  used('Usado'),

  /// Venció por tiempo sin haberse usado.
  expired('Vencido');

  const QrState(this.label);
  final String label;
}

/// Boleto con código QR único de una renta (HU-15, HU-17).
///
/// El QR se genera automáticamente tras confirmar el pago. El [token] es
/// único e irrepetible; [signature] simula la firma digital (el backend la
/// hará con criptografía real, RNF-05). Es de un solo uso por fase: al
/// procesarse pasa a [QrState.used]; si expira, a [QrState.expired].
class QrTicket {
  const QrTicket({
    required this.token,
    required this.signature,
    required this.phase,
    required this.issuedAt,
    required this.expiresAt,
    this.used = false,
  });

  /// Identificador único e irrepetible del boleto.
  final String token;

  /// Firma simulada del payload (en backend sería criptográfica).
  final String signature;

  final QrPhase phase;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool used;

  /// Payload que se codifica dentro del QR. Incluye token y firma para que
  /// Recepción pueda validarlo (Épica 4).
  String get payload => 'SRUU|$token|${phase.name}|$signature';

  /// Estado de vigencia evaluado contra [now] (HU-17).
  QrState stateAt(DateTime now) {
    if (used) return QrState.used;
    if (now.isAfter(expiresAt)) return QrState.expired;
    return QrState.valid;
  }

  bool isValidAt(DateTime now) => stateAt(now) == QrState.valid;

  QrTicket copyWith({bool? used}) {
    return QrTicket(
      token: token,
      signature: signature,
      phase: phase,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      used: used ?? this.used,
    );
  }
}
