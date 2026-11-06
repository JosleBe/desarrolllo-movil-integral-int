import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/incidence.dart';
import 'providers/admin_providers.dart';

/// Panel del Administrador para revisar y resolver incidencias (HU-23).
class IncidencesPage extends ConsumerWidget {
  const IncidencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidences = ref.watch(incidencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Incidencias')),
      body: incidences.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No hay incidencias reportadas.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _IncidenceTile(incidence: items[index]),
          );
        },
      ),
    );
  }
}

class _IncidenceTile extends ConsumerWidget {
  const _IncidenceTile({required this.incidence});

  final Incidence incidence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final open = incidence.isOpen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    incidence.rentalTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(incidence.status.label),
                  backgroundColor: open
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.secondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${incidence.type.label} · por ${incidence.reportedBy}'),
            const SizedBox(height: 8),
            Text(incidence.description, style: theme.textTheme.bodyMedium),
            if (incidence.resolution != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Resolución: ${incidence.resolution}'),
              ),
            ],
            if (open) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _resolve(context, ref),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Resolver'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final resolution = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolver incidencia'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Resolución',
            hintText: 'Describe cómo se resolvió el caso',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resolution == null || resolution.trim().isEmpty) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(adminActionsProvider)
        .resolveIncidence(incidenceId: incidence.id, resolution: resolution);
    messenger.showSnackBar(
      const SnackBar(content: Text('Incidencia resuelta y registrada')),
    );
  }
}
