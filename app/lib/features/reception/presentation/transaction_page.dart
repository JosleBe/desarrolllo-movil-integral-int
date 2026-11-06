import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rentals/domain/rental.dart';
import '../../rentals/domain/rental_repository.dart';
import '../../rentals/domain/rental_status.dart';
import '../../rentals/presentation/providers/rentals_providers.dart';
import '../../admin/presentation/incidence_form_page.dart';
import 'providers/reception_providers.dart';

/// Datos de la transacción y acciones de Recepción (HU-18 a HU-21).
///
/// Según el estado de la renta, ofrece: recibir del Vendedor (CONFIRMADA),
/// entregar al Rentador (EN RECEPCIÓN), o registrar la devolución
/// (EN RENTA).
class TransactionPage extends ConsumerWidget {
  const TransactionPage({required this.rentalId, super.key});

  final String rentalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(rentalDetailProvider(rentalId));

    return Scaffold(
      appBar: AppBar(title: const Text('Transacción')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rental) {
          if (rental == null) {
            return const Center(child: Text('Transacción no encontrada'));
          }
          return _TransactionBody(rental: rental);
        },
      ),
    );
  }
}

class _TransactionBody extends ConsumerWidget {
  const _TransactionBody({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rental.listingTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Chip(label: Text(rental.status.label)),
                  ],
                ),
                const Divider(height: 24),
                _Info(label: 'Rentador', value: rental.renterName),
                _Info(label: 'Vendedor', value: rental.ownerName),
                _Info(label: 'Periodo', value: rental.period.label),
                if (rental.itemConditionNote != null)
                  _Info(
                    label: 'Estado del artículo',
                    value: rental.itemConditionNote!,
                  ),
                if (rental.receivedBy != null)
                  _Info(label: 'Recibido por', value: rental.receivedBy!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ActionsForStatus(rental: rental),
      ],
    );
  }
}

/// Muestra la acción de Recepción correspondiente al estado de la renta.
class _ActionsForStatus extends ConsumerWidget {
  const _ActionsForStatus({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (rental.status) {
      RentalStatus.confirmed => _ReceiveAction(rental: rental),
      RentalStatus.inReception => _DeliverAction(rental: rental),
      RentalStatus.onRent => _ReturnAction(rental: rental),
      _ => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hay acciones de recepción para el estado '
            '"${rental.status.label}".',
          ),
        ),
      ),
    };
  }
}

/// HU-19: recibir el artículo del Vendedor con nota del estado.
class _ReceiveAction extends ConsumerStatefulWidget {
  const _ReceiveAction({required this.rental});
  final Rental rental;

  @override
  ConsumerState<_ReceiveAction> createState() => _ReceiveActionState();
}

class _ReceiveActionState extends ConsumerState<_ReceiveAction> {
  final _noteController = TextEditingController(text: 'Buen estado');
  bool _busy = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _receive() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(receptionActionsProvider).receive(
            rentalId: widget.rental.id,
            itemCondition: _noteController.text.trim(),
            receivedBy: 'Recepción',
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Artículo recibido (EN RECEPCIÓN)')),
      );
    } on RentalException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recibir del Vendedor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Estado del artículo',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _receive,
              icon: const Icon(Icons.inventory),
              label: const Text('Registrar recepción'),
            ),
          ],
        ),
      ),
    );
  }
}

/// HU-20: entregar al Rentador (solo tras QR válido, RN-05).
class _DeliverAction extends ConsumerStatefulWidget {
  const _DeliverAction({required this.rental});
  final Rental rental;

  @override
  ConsumerState<_DeliverAction> createState() => _DeliverActionState();
}

class _DeliverActionState extends ConsumerState<_DeliverAction> {
  bool _busy = false;

  Future<void> _deliver() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(receptionActionsProvider).deliver(
            rentalId: widget.rental.id,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Artículo entregado (EN RENTA)')),
      );
    } on RentalException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Entregar al Rentador',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'La entrega requiere un QR válido ya escaneado (RN-05).',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _deliver,
              icon: const Icon(Icons.handshake),
              label: const Text('Confirmar entrega'),
            ),
          ],
        ),
      ),
    );
  }
}

/// HU-21: registrar la devolución y el retorno al Vendedor.
class _ReturnAction extends ConsumerStatefulWidget {
  const _ReturnAction({required this.rental});
  final Rental rental;

  @override
  ConsumerState<_ReturnAction> createState() => _ReturnActionState();
}

class _ReturnActionState extends ConsumerState<_ReturnAction> {
  final _noteController = TextEditingController(text: 'Sin daños');
  bool _busy = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _return() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(receptionActionsProvider).registerReturn(
            rentalId: widget.rental.id,
            itemCondition: _noteController.text.trim(),
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Devolución registrada (FINALIZADA)')),
      );
    } on RentalException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registrar devolución',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Estado del artículo al devolver',
              ),
            ),
            const SizedBox(height: 8),
            // Acceso a incidencia (HU-22).
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => IncidenceFormPage(
                          rentalId: widget.rental.id,
                          rentalTitle: widget.rental.listingTitle,
                        ),
                      ),
                    ),
              icon: const Icon(Icons.report_problem_outlined, size: 18),
              label: const Text('Reportar incidencia'),
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: _busy ? null : _return,
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text('Registrar devolución'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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
