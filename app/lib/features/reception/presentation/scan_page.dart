import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rentals/data/mock_rental_repository.dart';
import '../../rentals/presentation/providers/rentals_providers.dart';
import '../domain/qr_validation.dart';
import 'providers/reception_providers.dart';
import 'transaction_page.dart';

/// Escaneo y validación del QR en Recepción (HU-18).
///
/// Para compatibilidad con web, el "escaneo" se hace por entrada manual
/// del payload (se puede pegar el contenido del QR). La validación de
/// firma, fase y vigencia es idéntica a la que haría la cámara. Integrar
/// `mobile_scanner` para capturar con cámara real es una mejora futura.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final _controller = TextEditingController();
  bool _validating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _useSamplePayload() {
    final repo = ref.read(rentalRepositoryProvider);
    if (repo is MockRentalRepository) {
      setState(() => _controller.text = repo.seedPickupPayload);
    }
  }

  Future<void> _validate() async {
    final payload = _controller.text.trim();
    if (payload.isEmpty) return;

    setState(() => _validating = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = await ref
        .read(receptionActionsProvider)
        .validatePickup(payload);

    if (!mounted) return;
    setState(() => _validating = false);

    switch (result) {
      case QrValid(:final rental):
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => TransactionPage(rentalId: rental.id),
          ),
        );
      case QrRejected(:final reason):
        // Un QR falso, vencido o de otra fase se rechaza y se avisa (HU-18).
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('QR rechazado: ${reason.message}'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Sin AppBar: la barra superior la provee el HomeShell.
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Escanea o ingresa el código del boleto',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La captura con cámara se habilitará en móvil. Por '
                    'ahora, pega el contenido del QR.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    enabled: !_validating,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Contenido del QR',
                      hintText: 'SRUU|...|pickup|...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _validating ? null : _useSamplePayload,
                    icon: const Icon(Icons.content_paste, size: 18),
                    label: const Text('Usar un QR de ejemplo'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _validating ? null : _validate,
                    icon: _validating
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_validating ? 'Validando...' : 'Validar QR'),
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
