import '../domain/admin_repositories.dart';
import '../domain/audit_entry.dart';

/// Bitácora de auditoría en memoria (HU-26, RNF-08).
///
/// Solo permite insertar y consultar; no expone edición ni borrado, de
/// modo que los registros son inmutables. Incluye algunas entradas de
/// ejemplo para la demo.
class MockAuditRepository implements AuditRepository {
  MockAuditRepository() {
    _seed();
  }

  static const _delay = Duration(milliseconds: 250);

  final List<AuditEntry> _entries = [];
  int _counter = 0;

  void _seed() {
    final now = DateTime.now();
    _entries.add(
      AuditEntry(
        id: _nextId(),
        actor: 'Usuario Demo',
        action: AuditAction.incidenceResolved,
        target: 'Incidencia #demo',
        timestamp: now.subtract(const Duration(days: 1)),
        previousState: 'Abierta',
        newState: 'Resuelta',
      ),
    );
  }

  String _nextId() => 'a-${_counter++}';

  @override
  Future<void> record(AuditEntry entry) async {
    await Future<void>.delayed(_delay);
    _entries.add(entry);
  }

  @override
  Future<List<AuditEntry>> query(AuditFilters filters) async {
    await Future<void>.delayed(_delay);
    return _entries.where((e) {
        if (filters.actor != null &&
            !e.actor.toLowerCase().contains(filters.actor!.toLowerCase())) {
          return false;
        }
        if (filters.action != null && e.action != filters.action) return false;
        if (filters.from != null && e.timestamp.isBefore(filters.from!)) {
          return false;
        }
        if (filters.to != null && e.timestamp.isAfter(filters.to!)) {
          return false;
        }
        return true;
      }).toList()
      // Más recientes primero.
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Genera un id para una entrada nueva creada desde fuera (controllers).
  String generateId() => _nextId();
}
