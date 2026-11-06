import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/catalog_enums.dart';
import '../../catalog/domain/listing.dart';
import 'providers/admin_providers.dart';

/// Moderación del catálogo por el Administrador (HU-27).
///
/// Lista todas las publicaciones (incluidas las pausadas) y permite
/// pausarlas o eliminarlas indicando un motivo. Cada acción se registra
/// en la bitácora.
class ModerationPage extends ConsumerWidget {
  const ModerationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(allListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moderar catálogo')),
      body: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No hay publicaciones.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _ModerationTile(listing: items[index]),
          );
        },
      ),
    );
  }
}

class _ModerationTile extends ConsumerWidget {
  const _ModerationTile({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = listing.status == ListingStatus.paused;

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
                    listing.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(listing.status.label)),
              ],
            ),
            Text('De ${listing.ownerName} · ${listing.category.label}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                if (!paused)
                  OutlinedButton.icon(
                    onPressed: () => _moderate(context, ref, remove: false),
                    icon: const Icon(Icons.pause, size: 18),
                    label: const Text('Pausar'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _moderate(context, ref, remove: true),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moderate(
    BuildContext context,
    WidgetRef ref, {
    required bool remove,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(remove ? 'Eliminar publicación' : 'Pausar publicación'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Motivo (obligatorio)',
            ),
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
            child: Text(remove ? 'Eliminar' : 'Pausar'),
          ),
        ],
      ),
    );

    if (reason == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final actions = ref.read(adminActionsProvider);
      if (remove) {
        await actions.moderateRemove(listing: listing, reason: reason);
      } else {
        await actions.moderatePause(listing: listing, reason: reason);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            remove ? 'Publicación eliminada' : 'Publicación pausada',
          ),
        ),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('AdminException: ', '')),
        ),
      );
    }
  }
}
