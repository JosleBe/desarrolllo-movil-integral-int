import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/user.dart';
import 'providers/admin_providers.dart';

/// Panel del Administrador para gestionar permisos de usuarios (HU-24/25).
///
/// Permite suspender (con motivo obligatorio, RN-03) o reactivar cada
/// permiso (Rentador/Vendedor) de forma individual, sin afectar al otro
/// (RN-02). Cada acción queda en la bitácora.
class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios y permisos')),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _UserTile(user: items[index]),
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.fullName, style: theme.textTheme.titleMedium),
            Text(user.email, style: theme.textTheme.bodySmall),
            const Divider(height: 20),
            _PermissionControl(
              user: user,
              permission: ManagedPermission.renter,
              active: user.permissions.renter,
            ),
            _PermissionControl(
              user: user,
              permission: ManagedPermission.seller,
              active: user.permissions.seller,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionControl extends ConsumerWidget {
  const _PermissionControl({
    required this.user,
    required this.permission,
    required this.active,
  });

  final User user;
  final ManagedPermission permission;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.block,
            size: 18,
            color: active ? scheme.primary : scheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(permission.label)),
          Text(
            active ? 'Activo' : 'Suspendido',
            style: TextStyle(color: active ? scheme.primary : scheme.error),
          ),
          const SizedBox(width: 8),
          if (active)
            OutlinedButton(
              onPressed: () => _suspend(context, ref),
              child: const Text('Suspender'),
            )
          else
            FilledButton.tonal(
              onPressed: () => _reactivate(context, ref),
              child: const Text('Reactivar'),
            ),
        ],
      ),
    );
  }

  Future<void> _suspend(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspender ${permission.label}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Motivo (obligatorio)',
            ),
            // RN-03: sin motivo no se puede suspender.
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'El motivo es obligatorio'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: const Text('Suspender'),
          ),
        ],
      ),
    );

    if (reason == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(adminActionsProvider)
          .suspendPermission(
            user: user,
            permission: permission,
            reason: reason,
          );
      messenger.showSnackBar(
        SnackBar(content: Text('${permission.label} suspendido')),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('AdminException: ', '')),
        ),
      );
    }
  }

  Future<void> _reactivate(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(adminActionsProvider)
        .reactivatePermission(user: user, permission: permission);
    messenger.showSnackBar(
      SnackBar(content: Text('${permission.label} reactivado')),
    );
  }
}
