import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/rental.dart';
import '../domain/rental_repository.dart';
import '../domain/rental_status.dart';
import 'providers/rental_actions.dart';
import 'providers/rentals_providers.dart';

/// Vista de las rentas del Vendedor con filtro por estado y acciones de aprobación/rechazo (HU-12, HU-38).
class MyRentalsPage extends ConsumerWidget {
  const MyRentalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentals = ref.watch(sellerRentalsProvider);
    final filter = ref.watch(rentalFilterProvider);

    // Estados relevantes para el Vendedor (HU-12, HU-38).
    const options = <RentalStatus>[
      RentalStatus.pendingApproval,
      RentalStatus.approved,
      RentalStatus.confirmed,
      RentalStatus.onRent,
      RentalStatus.returned,
      RentalStatus.finished,
      RentalStatus.rejected,
    ];

    return Scaffold(
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
                      _SellerRentalTile(rental: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerRentalTile extends ConsumerWidget {
  const _SellerRentalTile({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPending = rental.isPendingApproval || rental.isRequested;

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
                    rental.listingTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(rental.status.label),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Rentador: ${rental.renterName}\n'
              'Periodo: ${_date(rental.startDate)} — ${_date(rental.endDate)}\n'
              'Monto: \$${rental.amount.toStringAsFixed(2)} MXN',
              style: theme.textTheme.bodyMedium,
            ),
            if (rental.rejectionReason != null && rental.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Motivo de rechazo: ${rental.rejectionReason}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.shade800),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context, ref),
                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                      label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                    ),
                    FilledButton.icon(
                      onPressed: () => _approve(context, ref),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aprobar'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(rentalActionsProvider).approve(rental.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Solicitud aprobada con éxito')),
      );
    } on RentalException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Deseas indicar un motivo opcional para el Rentador?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo de rechazo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar Rechazo'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(rentalActionsProvider)
          .reject(rental.id, reason: reasonController.text.trim());
      messenger.showSnackBar(
        const SnackBar(content: Text('Solicitud rechazada')),
      );
    } on RentalException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
