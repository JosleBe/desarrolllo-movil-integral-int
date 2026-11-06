import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rentals/presentation/rent_request_page.dart';
import '../domain/listing.dart';
import 'price_format.dart';
import 'providers/catalog_providers.dart';
import 'widgets/listing_gallery.dart';

/// Detalle de una publicación (HU-08, HU-09, HU-11).
///
/// Muestra galería, descripción, categoría, estado del artículo y todos
/// los periodos con su precio.
class ListingDetailPage extends ConsumerWidget {
  const ListingDetailPage({required this.listingId, super.key});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(listingDetailProvider(listingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listing) {
          if (listing == null) {
            return const Center(
              child: Text('La publicación ya no está disponible'),
            );
          }
          return _DetailBody(listing: listing);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListingGallery(imageUrls: listing.imageUrls),
        const SizedBox(height: 16),
        Row(
          children: [
            Chip(label: Text(listing.category.label)),
            const SizedBox(width: 8),
            Chip(label: Text(listing.condition.label)),
          ],
        ),
        const SizedBox(height: 12),
        Text(listing.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Publicado por ${listing.ownerName}',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        Text(listing.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        Text('Precios y periodos', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...listing.prices.map(
          (option) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(option.period.label),
            trailing: Text(
              PriceFormat.money(option.amount),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: listing.isRentable
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RentRequestPage(listing: listing),
                  ),
                )
              : null,
          icon: const Icon(Icons.shopping_cart_outlined),
          label: Text(
            listing.isRentable ? 'Solicitar renta' : 'No disponible',
          ),
        ),
      ],
    );
  }
}
