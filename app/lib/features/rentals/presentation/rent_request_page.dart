import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/catalog_enums.dart';
import '../../catalog/domain/listing.dart';
import '../../catalog/presentation/price_format.dart';
import '../domain/rental_repository.dart';
import 'providers/rental_actions.dart';

/// Solicitud de renta de un artículo (HU-13).
///
/// Permite elegir el periodo ofrecido por la publicación y el rango de
/// fechas, estima el monto y crea la renta en estado SOLICITADA. Si hay
/// traslape de fechas (RN-04) se avisa al usuario.
class RentRequestPage extends ConsumerStatefulWidget {
  const RentRequestPage({required this.listing, super.key});

  final Listing listing;

  @override
  ConsumerState<RentRequestPage> createState() => _RentRequestPageState();
}

class _RentRequestPageState extends ConsumerState<RentRequestPage> {
  late RentalPeriod _period;
  DateTimeRange? _range;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _period = widget.listing.prices.first.period;
    final now = DateTime.now();
    _range = DateTimeRange(
      start: now,
      end: now.add(const Duration(days: 1)),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _submit() async {
    final range = _range;
    if (range == null) return;

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(rentalActionsProvider).request(
            RentalRequest(
              listingId: widget.listing.id,
              period: _period,
              startDate: range.start,
              // Si eligen el mismo día, damos al menos +1 día de lapso.
              endDate: range.end.isAfter(range.start)
                  ? range.end
                  : range.start.add(const Duration(days: 1)),
            ),
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Solicitud creada. Ya puedes pagarla.'),
        ),
      );
      navigator.pop();
    } on RentalException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar renta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(listing.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  Text('Periodo', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  // Solo los periodos que la publicación ofrece.
                  Wrap(
                    spacing: 8,
                    children: listing.prices
                        .map(
                          (option) => ChoiceChip(
                            label: Text(
                              '${option.period.label} · '
                              '${PriceFormat.money(option.amount)}',
                            ),
                            selected: _period == option.period,
                            onSelected: (_) =>
                                setState(() => _period = option.period),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('Fechas', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _range == null
                          ? 'Elegir fechas'
                          : '${_fmt(_range!.start)} — ${_fmt(_range!.end)}',
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Solicitar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
