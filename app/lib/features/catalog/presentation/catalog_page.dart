import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../domain/catalog_enums.dart';
import 'providers/catalog_providers.dart';
import 'widgets/listing_card.dart';

/// Catálogo con búsqueda avanzada y filtros combinables (HU-10, HU-11).
class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(catalogResultsProvider);
    final filters = ref.watch(catalogFiltersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar útiles...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filters.query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => ref
                          .read(catalogFiltersProvider.notifier)
                          .setQuery(''),
                    )
                  : null,
            ),
            onChanged: (value) =>
                ref.read(catalogFiltersProvider.notifier).setQuery(value),
          ),
        ),
        const _FilterBar(),
        Expanded(
          child: results.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (listings) {
              if (listings.isEmpty) {
                return const _EmptyState();
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width > 720 ? 2 : 1;
                  final columnWidth =
                      (width - 32 - (columns - 1) * 12) / columns;
                  final extent = (columnWidth * 0.62).clamp(220.0, 260.0);
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: extent,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return ListingCard(
                        listing: listing,
                        onTap: () => context.push(
                          AppRoutes.listingDetail(listing.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(catalogFiltersProvider);
    final controller = ref.read(catalogFiltersProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Category?>(
                  initialValue: filters.category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    isDense: true,
                  ),
                  onChanged: controller.setCategory,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...Category.values.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<RentalPeriod?>(
                  initialValue: filters.period,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Periodo',
                    isDense: true,
                  ),
                  onChanged: controller.setPeriod,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Cualquiera'),
                    ),
                    ...RentalPeriod.values.map(
                      (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('Solo disponibles'),
                selected: filters.onlyAvailable,
                onSelected: controller.setOnlyAvailable,
              ),
              const Spacer(),
              if (!filters.isEmpty)
                TextButton.icon(
                  onPressed: controller.clear,
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text('Limpiar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin coincidencias',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otras palabras o quita algunos filtros para '
              'ampliar la búsqueda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(catalogFiltersProvider.notifier).clear(),
              child: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
