import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/rental.dart';
import '../domain/rental_status.dart';
import 'providers/rentals_providers.dart';

/// Vista de las rentas del Vendedor con filtro por estado (HU-12).
class MyRentalsPage extends ConsumerWidget {
  const MyRentalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentals = ref.watch(sellerRentalsProvider);
    final filter = ref.watch(rentalFilterProvider);

    // Estados relevantes para el Vendedor en HU-12.
    const options = <RentalStatus>[
      RentalStatus.confirmed,
      RentalStatus.onRent,
      RentalStatus.returned,
      RentalStatus.finished,
    ];

    return Scaffold(
      // Sin AppBar: la barra superior la provee el HomeShell.
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: filter == null,
                  onSelected: (_) =>
                      ref.read(rentalFilterProvider.notifier).set(null),
                ),
                const SizedBox(width: 8),
                ...options.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status.label),
                      selected: filter == status,
                      onSelected: (_) => ref
                          .read(rentalFilterProvider.notifier)
                          .set(status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: rentals.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No hay rentas con ese estado'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _RentalTile(rental: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RentalTile extends StatelessWidget {
  const _RentalTile({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(rental.listingTitle),
        subtitle: Text(
          'Rentador: ${rental.renterName}\n'
          '${_date(rental.startDate)} — ${_date(rental.endDate)}',
        ),
        isThreeLine: true,
        trailing: Chip(label: Text(rental.status.label)),
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
