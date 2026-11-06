import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_controller.dart';
import '../domain/admin_repositories.dart';
import '../domain/incidence.dart';
import 'providers/admin_providers.dart';

/// Formulario para reportar una incidencia (HU-22).
///
/// Lo puede abrir Vendedor, Rentador o Recepción desde una renta. Permite
/// elegir el tipo (daño, demora, faltante, no entregado) y describir el
/// problema. Al enviarlo, la renta pasa a estado INCIDENCIA.
class IncidenceFormPage extends ConsumerStatefulWidget {
  const IncidenceFormPage({
    required this.rentalId,
    required this.rentalTitle,
    super.key,
  });

  final String rentalId;
  final String rentalTitle;

  @override
  ConsumerState<IncidenceFormPage> createState() => _IncidenceFormPageState();
}

class _IncidenceFormPageState extends ConsumerState<IncidenceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  IncidenceType _type = IncidenceType.damage;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final reporter =
        ref.read(authControllerProvider).user?.fullName ?? 'Usuario';

    try {
      await ref
          .read(adminActionsProvider)
          .reportIncidence(
            IncidenceDraft(
              rentalId: widget.rentalId,
              rentalTitle: widget.rentalTitle,
              type: _type,
              description: _descriptionController.text,
              reportedBy: reporter,
            ),
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Incidencia registrada. La renta pasó a INCIDENCIA.'),
        ),
      );
      navigator.pop();
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('AdminException: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar incidencia')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.rentalTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<IncidenceType>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de incidencia',
                      ),
                      items: IncidenceType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() => _type = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_submitting,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Describe lo ocurrido'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reportar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
