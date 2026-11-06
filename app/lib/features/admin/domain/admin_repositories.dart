import 'audit_entry.dart';
import 'incidence.dart';

/// Errores de dominio del módulo Admin (Épica 5).
sealed class AdminException implements Exception {
  const AdminException(this.message);
  final String message;
  @override
  String toString() => 'AdminException: $message';
}

/// Se intentó suspender un permiso sin motivo (RN-03, HU-24).
class ReasonRequired extends AdminException {
  const ReasonRequired() : super('Debes registrar un motivo para esta acción');
}

/// Datos para reportar una incidencia (HU-22).
class IncidenceDraft {
  const IncidenceDraft({
    required this.rentalId,
    required this.rentalTitle,
    required this.type,
    required this.description,
    required this.reportedBy,
  });

  final String rentalId;
  final String rentalTitle;
  final IncidenceType type;
  final String description;
  final String reportedBy;
}

/// Contrato de incidencias (HU-22, HU-23).
abstract interface class IncidenceRepository {
  /// Crea una incidencia; la renta asociada pasa a INCIDENCIA (HU-22).
  Future<Incidence> report(IncidenceDraft draft);

  /// Lista todas las incidencias (panel del Administrador, HU-23).
  Future<List<Incidence>> listAll();

  /// Resuelve una incidencia con un texto de resolución (HU-23).
  Future<Incidence> resolve({
    required String incidenceId,
    required String resolution,
    required String resolvedBy,
  });
}

/// Filtros de la bitácora de auditoría (HU-26).
class AuditFilters {
  const AuditFilters({this.actor, this.action, this.from, this.to});

  final String? actor;
  final AuditAction? action;
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty =>
      actor == null && action == null && from == null && to == null;
}

/// Contrato de la bitácora de auditoría (HU-26, RNF-08).
///
/// Solo permite insertar y consultar: no hay métodos para editar ni
/// borrar, reflejando la inmutabilidad exigida por RNF-08.
abstract interface class AuditRepository {
  /// Registra una acción crítica en la bitácora.
  Future<void> record(AuditEntry entry);

  /// Consulta la bitácora aplicando filtros combinables (HU-26).
  Future<List<AuditEntry>> query(AuditFilters filters);
}
