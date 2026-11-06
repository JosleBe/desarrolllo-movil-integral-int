import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/audit_entry.dart';
import 'providers/admin_providers.dart';

/// Vista de la bitácora de auditoría (HU-26, RNF-08).
///
/// Lista las acciones críticas (quién, qué, cuándo, estado anterior/nuevo)
/// con filtros por actor y tipo de acción. Los registros son inmutables:
/// la vista es de solo lectura.
class AuditLogPage extends ConsumerWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(auditEntriesProvider);
    final filters = ref.watch(auditFiltersProvider);
    final controller = ref.read(auditFiltersProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Bitácora de auditoría')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por usuario',
                    isDense: true,
                  ),
                  onChanged: controller.setActor,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AuditAction?>(
                        initialValue: filters.action,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Acción',
                          isDense: true,
                        ),
                        onChanged: controller.setAction,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...AuditAction.values.map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(a.label),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!filters.isEmpty)
                      IconButton(
                        tooltip: 'Limpiar filtros',
                        icon: const Icon(Icons.filter_alt_off),
                        onPressed: controller.clear,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Sin registros para esos filtros.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _AuditTile(entry: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = (entry.previousState != null && entry.newState != null)
        ? '${entry.previousState} → ${entry.newState}'
        : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: const Icon(Icons.history),
      title: Text(entry.action.label, style: theme.textTheme.titleSmall),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${entry.actor} · ${entry.target}'),
          if (change != null) Text(change),
          if (entry.reason != null) Text('Motivo: ${entry.reason}'),
          Text(_fmt(entry.timestamp), style: theme.textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
