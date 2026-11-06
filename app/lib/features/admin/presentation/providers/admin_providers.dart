import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../catalog/domain/listing.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../rentals/presentation/providers/rentals_providers.dart';
import '../../data/mock_audit_repository.dart';
import '../../data/mock_incidence_repository.dart';
import '../../domain/admin_repositories.dart';
import '../../domain/audit_entry.dart';
import '../../domain/incidence.dart';

// ---------------------------------------------------------------------------
// Repositorios (singletons en memoria)
// ---------------------------------------------------------------------------

final auditRepositoryProvider = Provider<MockAuditRepository>(
  (ref) => MockAuditRepository(),
);

final incidenceRepositoryProvider = Provider<IncidenceRepository>((ref) {
  return MockIncidenceRepository(
    ref.watch(rentalRepositoryProvider),
    ref.watch(auditRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Incidencias (HU-22/23)
// ---------------------------------------------------------------------------

final incidencesProvider = FutureProvider<List<Incidence>>((ref) {
  return ref.watch(incidenceRepositoryProvider).listAll();
});

// ---------------------------------------------------------------------------
// Usuarios (HU-24/25)
// ---------------------------------------------------------------------------

final adminUsersProvider = FutureProvider<List<User>>((ref) {
  return ref.watch(authRepositoryProvider).listUsers();
});

// ---------------------------------------------------------------------------
// Bitácora de auditoría (HU-26)
// ---------------------------------------------------------------------------

final auditFiltersProvider =
    NotifierProvider<AuditFiltersController, AuditFilters>(
      AuditFiltersController.new,
    );

class AuditFiltersController extends Notifier<AuditFilters> {
  @override
  AuditFilters build() => const AuditFilters();

  void setActor(String? actor) => state = AuditFilters(
    actor: (actor == null || actor.isEmpty) ? null : actor,
    action: state.action,
    from: state.from,
    to: state.to,
  );

  void setAction(AuditAction? action) => state = AuditFilters(
    actor: state.actor,
    action: action,
    from: state.from,
    to: state.to,
  );

  void clear() => state = const AuditFilters();
}

final auditEntriesProvider = FutureProvider<List<AuditEntry>>((ref) {
  final filters = ref.watch(auditFiltersProvider);
  return ref.watch(auditRepositoryProvider).query(filters);
});

// ---------------------------------------------------------------------------
// Moderación del catálogo (HU-27)
// ---------------------------------------------------------------------------

final allListingsProvider = FutureProvider<List<Listing>>((ref) {
  return ref.watch(listingRepositoryProvider).listAll();
});

// ---------------------------------------------------------------------------
// Acciones del Administrador
// ---------------------------------------------------------------------------

final adminActionsProvider = Provider<AdminActions>(AdminActions.new);

class AdminActions {
  AdminActions(this._ref);

  final Ref _ref;

  String get _adminName =>
      _ref.read(authControllerProvider).user?.fullName ?? 'Administrador';

  /// Reporta una incidencia (HU-22) y refresca el listado.
  Future<void> reportIncidence(IncidenceDraft draft) async {
    await _ref.read(incidenceRepositoryProvider).report(draft);
    _ref.invalidate(incidencesProvider);
  }

  /// Resuelve una incidencia (HU-23) y refresca listado y bitácora.
  Future<void> resolveIncidence({
    required String incidenceId,
    required String resolution,
  }) async {
    await _ref
        .read(incidenceRepositoryProvider)
        .resolve(
          incidenceId: incidenceId,
          resolution: resolution,
          resolvedBy: _adminName,
        );
    _ref.invalidate(incidencesProvider);
    _ref.invalidate(auditEntriesProvider);
  }

  /// Suspende un permiso con motivo obligatorio (HU-24, RN-03). Registra en
  /// la bitácora y no afecta al otro permiso (RN-02). Lanza [ReasonRequired]
  /// si el motivo está vacío.
  Future<void> suspendPermission({
    required User user,
    required ManagedPermission permission,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) throw const ReasonRequired();
    await _ref
        .read(authRepositoryProvider)
        .setPermission(userId: user.id, permission: permission, active: false);
    await _recordPermissionChange(
      user: user,
      permission: permission,
      action: AuditAction.permissionSuspended,
      from: 'Activo',
      to: 'Suspendido',
      reason: reason.trim(),
    );
    _refreshAdmin();
  }

  /// Reactiva un permiso individual (HU-25). Queda registrado en bitácora.
  Future<void> reactivatePermission({
    required User user,
    required ManagedPermission permission,
    String? reason,
  }) async {
    await _ref
        .read(authRepositoryProvider)
        .setPermission(userId: user.id, permission: permission, active: true);
    await _recordPermissionChange(
      user: user,
      permission: permission,
      action: AuditAction.permissionReactivated,
      from: 'Suspendido',
      to: 'Activo',
      reason: reason?.trim(),
    );
    _refreshAdmin();
  }

  /// Pausa una publicación como moderación, con motivo (HU-27).
  Future<void> moderatePause({
    required Listing listing,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) throw const ReasonRequired();
    await _ref
        .read(listingRepositoryProvider)
        .moderatePause(listingId: listing.id, reason: reason.trim());
    await _recordModeration(listing, reason.trim(), 'Pausada');
    _refreshModeration();
  }

  /// Elimina una publicación como moderación, con motivo (HU-27).
  Future<void> moderateRemove({
    required Listing listing,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) throw const ReasonRequired();
    await _ref
        .read(listingRepositoryProvider)
        .moderateRemove(listingId: listing.id, reason: reason.trim());
    await _recordModeration(listing, reason.trim(), 'Eliminada');
    _refreshModeration();
  }

  Future<void> _recordModeration(
    Listing listing,
    String reason,
    String action,
  ) async {
    final audit = _ref.read(auditRepositoryProvider);
    await audit.record(
      AuditEntry(
        id: audit.generateId(),
        actor: _adminName,
        action: AuditAction.listingModerated,
        target: 'Publicación "${listing.title}" de ${listing.ownerName}',
        timestamp: DateTime.now(),
        previousState: listing.status.label,
        newState: action,
        reason: reason,
      ),
    );
  }

  void _refreshModeration() {
    _ref.invalidate(allListingsProvider);
    _ref.invalidate(catalogResultsProvider);
    _ref.invalidate(auditEntriesProvider);
  }

  Future<void> _recordPermissionChange({
    required User user,
    required ManagedPermission permission,
    required AuditAction action,
    required String from,
    required String to,
    String? reason,
  }) async {
    final audit = _ref.read(auditRepositoryProvider);
    await audit.record(
      AuditEntry(
        id: audit.generateId(),
        actor: _adminName,
        action: action,
        target: '${user.fullName} · permiso ${permission.label}',
        timestamp: DateTime.now(),
        previousState: from,
        newState: to,
        reason: reason,
      ),
    );
  }

  void _refreshAdmin() {
    _ref.invalidate(adminUsersProvider);
    _ref.invalidate(auditEntriesProvider);
  }
}
