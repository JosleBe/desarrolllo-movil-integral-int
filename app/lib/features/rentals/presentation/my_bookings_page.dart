import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/presentation/price_format.dart';
import '../domain/rental.dart';
import '../domain/rental_repository.dart';
import 'payment_page.dart';
import 'providers/rental_actions.dart';
import 'providers/rentals_providers.dart';
import 'ticket_page.dart';

/// Rentas del Rentador con acciones según el estado (HU-14/15/16).
class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentals = ref.watch(myRentalsProvider);

    return Scaffold(
      // Sin AppBar: la barra superior la provee el HomeShell.
      body: rentals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aún no tienes solicitudes. Explora el catálogo y '
                  'solicita la renta de un útil.',
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
                _BookingTile(rental: items[index]),
          );
        },
      ),
    );
  }
}

class _BookingTile extends ConsumerWidget {
  const _BookingTile({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
              '${rental.period.label} · ${PriceFormat.money(rental.amount)}',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                if (rental.canPay)
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PaymentPage(rental: rental),
                      ),
                    ),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Pagar'),
                  ),
                if (rental.canCancel)
                  TextButton.icon(
                    onPressed: () => _cancel(context, ref),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancelar'),
                  ),
                if (rental.ticket != null)
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TicketPage(rentalId: rental.id),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('Ver boleto'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar solicitud'),
        content: const Text(
          '¿Seguro que quieres cancelar? El artículo volverá a estar '
          'disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(rentalActionsProvider).cancel(rental.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Solicitud cancelada')),
      );
    } on RentalException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
