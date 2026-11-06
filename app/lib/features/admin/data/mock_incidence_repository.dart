import '../../rentals/domain/rental_repository.dart';
import '../domain/admin_repositories.dart';
import '../domain/audit_entry.dart';
import '../domain/incidence.dart';

/// Incidencias en memoria (HU-22, HU-23).
///
/// Al reportar, transiciona la renta a INCIDENCIA mediante el
/// [RentalRepository]. Al resolver, registra la acción en la bitácora.
class MockIncidenceRepository implements IncidenceRepository {
  MockIncidenceRepository(this._rentals, this._audit);

  static const _delay = Duration(milliseconds: 300);

  final RentalRepository _rentals;
  final AuditRepository _audit;

  final Map<String, Incidence> _incidences = {};
  int _counter = 0;

  String _nextId() => 'i-${_counter++}';

  @override
  Future<Incidence> report(IncidenceDraft draft) async {
    await Future<void>.delayed(_delay);
    final incidence = Incidence(
      id: _nextId(),
      rentalId: draft.rentalId,
      rentalTitle: draft.rentalTitle,
      type: draft.type,
      description: draft.description.trim(),
      reportedBy: draft.reportedBy,
      createdAt: DateTime.now(),
    );
    _incidences[incidence.id] = incidence;
    // La renta asociada pasa a INCIDENCIA (HU-22).
    await _rentals.markIncidence(rentalId: draft.rentalId);
    return incidence;
  }

  @override
  Future<List<Incidence>> listAll() async {
    await Future<void>.delayed(_delay);
    return _incidences.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Incidence> resolve({
    required String incidenceId,
    required String resolution,
    required String resolvedBy,
  }) async {
    await Future<void>.delayed(_delay);
    final current = _incidences[incidenceId]!;
    final resolved = current.copyWith(
      status: IncidenceStatus.resolved,
      resolution: resolution.trim(),
      resolvedAt: DateTime.now(),
    );
    _incidences[incidenceId] = resolved;
    // Cada cambio queda en la bitácora (HU-23, RNF-08).
    await _audit.record(
      AuditEntry(
        id: 'audit-${DateTime.now().microsecondsSinceEpoch}',
        actor: resolvedBy,
        action: AuditAction.incidenceResolved,
        target: 'Incidencia ${current.id} (${current.rentalTitle})',
        timestamp: DateTime.now(),
        previousState: IncidenceStatus.open.label,
        newState: IncidenceStatus.resolved.label,
      ),
    );
    return resolved;
  }
}
