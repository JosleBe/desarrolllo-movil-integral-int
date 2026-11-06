/// Tipo de acción crítica registrada en la bitácora (RNF-08).
enum AuditAction {
  permissionSuspended('Permiso suspendido'),
  permissionReactivated('Permiso reactivado'),
  incidenceResolved('Incidencia resuelta'),
  listingModerated('Publicación moderada');

  const AuditAction(this.label);
  final String label;
}

/// Entrada inmutable de la bitácora de auditoría (HU-26, RNF-08).
///
/// Registra quién hizo qué, cuándo, y el estado anterior/nuevo. Todos los
/// campos son `final`: una entrada no se edita ni se borra; la bitácora
/// es de solo inserción.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.actor,
    required this.action,
    required this.target,
    required this.timestamp,
    this.previousState,
    this.newState,
    this.reason,
  });

  final String id;

  /// Quién realizó la acción (p. ej. el Administrador).
  final String actor;

  final AuditAction action;

  /// Sobre qué/quién recayó la acción (usuario, publicación, incidencia).
  final String target;

  final DateTime timestamp;

  final String? previousState;
  final String? newState;

  /// Motivo asociado (obligatorio en suspensiones, RN-03).
  final String? reason;
}
