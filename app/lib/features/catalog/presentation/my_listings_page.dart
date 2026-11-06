import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/catalog_enums.dart';
import '../domain/listing.dart';
import 'listing_form_page.dart';
import 'price_format.dart';
import 'providers/catalog_providers.dart';
import 'providers/listing_actions.dart';

/// Panel "Mis publicaciones" del Vendedor (HU-07).
///
/// Lista las publicaciones propias con acciones de editar, pausar,
/// reactivar y eliminar. La eliminación respeta la regla de no borrar con
/// rentas activas (RN-04).
class MyListingsPage extends ConsumerWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ListingFormPage(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
      body: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aún no tienes publicaciones. Toca "Publicar" para crear '
                  'la primera.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _MyListingTile(listing: items[index]),
          );
        },
      ),
    );
  }
}

class _MyListingTile extends ConsumerWidget {
  const _MyListingTile({required this.listing});

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
                Chip(
                  label: Text(listing.status.label),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(PriceFormat.lowestLabel(listing)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListingFormPage(listing: listing),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _toggleStatus(context, ref, paused),
                  icon: Icon(
                    paused ? Icons.play_arrow : Icons.pause,
                    size: 18,
                  ),
                  label: Text(paused ? 'Reactivar' : 'Pausar'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
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

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    bool paused,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(listingActionsProvider).setStatus(
          listing.id,
          paused ? ListingStatus.active : ListingStatus.paused,
        );
    messenger.showSnackBar(
      SnackBar(
        content: Text(paused ? 'Publicación reactivada' : 'Publicación pausada'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text('¿Seguro que quieres eliminar "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(listingActionsProvider).delete(listing.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Publicación eliminada')),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('CatalogException: ', '')),
        ),
      );
    }
  }
}
