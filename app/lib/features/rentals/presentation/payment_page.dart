import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/presentation/price_format.dart';
import '../domain/rental.dart';
import '../domain/rental_repository.dart';
import 'providers/rental_actions.dart';
import 'ticket_page.dart';

/// Pago de una renta (HU-14).
///
/// Simula la pasarela: un interruptor permite forzar un pago fallido para
/// probar el reintento. Con éxito, la renta pasa a CONFIRMADA, se genera
/// el boleto con QR y se navega a verlo.
class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({required this.rental, super.key});

  final Rental rental;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _paying = false;
  // Simulación: cuando está en false, el pago falla para probar reintento.
  bool _simulateSuccess = true;

  Future<void> _pay() async {
    setState(() => _paying = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final confirmed = await ref.read(rentalActionsProvider).pay(
            widget.rental.id,
            forceSuccess: _simulateSuccess,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Pago confirmado. Boleto generado.')),
      );
      // Reemplaza esta pantalla por el boleto con QR.
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TicketPage(rentalId: confirmed.id),
        ),
      );
    } on RentalException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rental = widget.rental;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pagar renta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _Row(label: 'Artículo', value: rental.listingTitle),
                          _Row(label: 'Periodo', value: rental.period.label),
                          _Row(
                            label: 'Total a pagar',
                            value: PriceFormat.money(rental.amount),
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Interruptor de simulación (solo para pruebas sin
                  // pasarela real).
                  SwitchListTile(
                    title: const Text('Simular pago exitoso'),
                    subtitle: const Text(
                      'Desactívalo para probar un pago fallido y el '
                      'reintento.',
                    ),
                    value: _simulateSuccess,
                    onChanged: _paying
                        ? null
                        : (v) => setState(() => _simulateSuccess = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _paying ? null : _pay,
                    icon: _paying
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payment),
                    label: Text(
                      _paying
                          ? 'Procesando...'
                          : 'Pagar ${PriceFormat.money(rental.amount)}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasize
        ? theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          )
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
