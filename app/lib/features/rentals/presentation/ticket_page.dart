import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../catalog/presentation/price_format.dart';
import '../domain/qr_ticket.dart';
import '../domain/rental.dart';
import 'providers/rentals_providers.dart';

/// Boleto con el código QR único de una renta (HU-15, HU-17).
///
/// Muestra el QR generado tras confirmar el pago, los datos de la renta y
/// el estado de vigencia (vigente / usado / vencido). El Rentador puede
/// consultarlo en cualquier momento.
class TicketPage extends ConsumerWidget {
  const TicketPage({required this.rentalId, super.key});

  final String rentalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(rentalDetailProvider(rentalId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mi boleto')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rental) {
          if (rental == null || rental.ticket == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Este boleto aún no está disponible. Se genera al '
                  'confirmarse el pago.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _TicketBody(rental: rental, ticket: rental.ticket!);
        },
      ),
    );
  }
}

class _TicketBody extends StatelessWidget {
  const _TicketBody({required this.rental, required this.ticket});

  final Rental rental;
  final QrTicket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ticket.stateAt(DateTime.now());
    final valid = state == QrState.valid;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              _StateBanner(state: state),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // El QR se atenúa si ya no es válido (HU-17).
                      Opacity(
                        opacity: valid ? 1 : 0.3,
                        child: Semantics(
                          label: 'Código QR del boleto de renta, '
                              'estado ${state.label}',
                          image: true,
                          child: QrImageView(
                            data: ticket.payload,
                            size: 220,
                            // ignore: deprecated_member_use
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fase: ${ticket.phase.label}',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Folio: ${ticket.token.substring(0, 12)}...',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Artículo', value: rental.listingTitle),
              _InfoRow(label: 'Monto', value: PriceFormat.money(rental.amount)),
              _InfoRow(label: 'Vence', value: _fmt(ticket.expiresAt)),
              if (rental.payment != null)
                _InfoRow(
                  label: 'Referencia de pago',
                  value: rental.payment!.reference,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _StateBanner extends StatelessWidget {
  const _StateBanner({required this.state});

  final QrState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, onColor, icon) = switch (state) {
      QrState.valid => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.verified,
      ),
      QrState.used => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        Icons.check_circle_outline,
      ),
      QrState.expired => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.timer_off,
      ),
    };

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: onColor),
            const SizedBox(width: 12),
            Text(
              'QR ${state.label}',
              style: TextStyle(
                color: onColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
