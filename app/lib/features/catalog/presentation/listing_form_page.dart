import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/catalog_enums.dart';
import '../domain/listing.dart';
import '../domain/listing_repository.dart';
import 'providers/listing_actions.dart';

/// Formulario para crear (HU-06) o editar (HU-07) una publicación, con
/// precios por periodo (HU-08) y una galería mock (HU-09).
///
/// Si [listing] es `null` es creación; si no, edición.
class ListingFormPage extends ConsumerStatefulWidget {
  const ListingFormPage({this.listing, super.key});

  final Listing? listing;

  bool get isEditing => listing != null;

  @override
  ConsumerState<ListingFormPage> createState() => _ListingFormPageState();
}

class _ListingFormPageState extends ConsumerState<ListingFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late Category _category;
  late ItemCondition _condition;
  late Map<RentalPeriod, double> _prices;
  late List<String> _imageUrls;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    _titleController = TextEditingController(text: listing?.title ?? '');
    _descriptionController =
        TextEditingController(text: listing?.description ?? '');
    _category = listing?.category ?? Category.calculator;
    _condition = listing?.condition ?? ItemCondition.good;
    _prices = {
      for (final option in listing?.prices ?? const <PriceOption>[])
        option.period: option.amount,
    };
    _imageUrls = List<String>.from(listing?.imageUrls ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_prices.isEmpty) {
      _showMessage('Agrega al menos un periodo con su precio');
      return;
    }

    final draft = ListingDraft(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category,
      condition: _condition,
      prices: _prices.entries
          .map((e) => PriceOption(period: e.key, amount: e.value))
          .toList(),
      imageUrls: _imageUrls,
    );

    setState(() => _saving = true);
    final actions = ref.read(listingActionsProvider);
    final navigator = Navigator.of(context);
    try {
      if (widget.isEditing) {
        await actions.update(widget.listing!.id, draft);
      } else {
        await actions.create(draft);
      }
      if (!mounted) return;
      _showMessage(
        widget.isEditing ? 'Publicación actualizada' : 'Publicación creada',
      );
      navigator.pop();
    } on Exception catch (e) {
      _showMessage(e.toString().replaceFirst('CatalogException: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar publicación' : 'Nueva publicación',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del útil *',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa un nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa una descripción'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Category>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                      ),
                      items: Category.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ItemCondition>(
                      initialValue: _condition,
                      decoration: const InputDecoration(
                        labelText: 'Estado del artículo',
                      ),
                      items: ItemCondition.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _condition = v!),
                    ),
                    const SizedBox(height: 24),
                    _PricesEditor(
                      prices: _prices,
                      enabled: !_saving,
                      onChanged: (prices) =>
                          setState(() => _prices = prices),
                    ),
                    const SizedBox(height: 24),
                    _GalleryEditor(
                      imageUrls: _imageUrls,
                      enabled: !_saving,
                      onChanged: (urls) =>
                          setState(() => _imageUrls = urls),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Guardar cambios'
                                  : 'Publicar',
                            ),
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

/// Editor de precios por periodo (HU-08). Permite activar hora/día/semana
/// y fijar un monto para cada uno.
class _PricesEditor extends StatelessWidget {
  const _PricesEditor({
    required this.prices,
    required this.enabled,
    required this.onChanged,
  });

  final Map<RentalPeriod, double> prices;
  final bool enabled;
  final ValueChanged<Map<RentalPeriod, double>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precios por periodo *',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Activa al menos un periodo e indica su precio en MXN.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ...RentalPeriod.values.map((period) {
          final active = prices.containsKey(period);
          return Row(
            children: [
              Checkbox(
                value: active,
                onChanged: enabled
                    ? (checked) {
                        final next = Map<RentalPeriod, double>.from(prices);
                        if (checked ?? false) {
                          next[period] = 0;
                        } else {
                          next.remove(period);
                        }
                        onChanged(next);
                      }
                    : null,
              ),
              Expanded(child: Text(period.label)),
              SizedBox(
                width: 140,
                child: TextFormField(
                  enabled: enabled && active,
                  initialValue: active && prices[period]! > 0
                      ? prices[period]!.toStringAsFixed(0)
                      : '',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0',
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    final next = Map<RentalPeriod, double>.from(prices);
                    next[period] = amount;
                    onChanged(next);
                  },
                  validator: (value) {
                    if (!active) return null;
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) return 'Precio > 0';
                    return null;
                  },
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

/// Editor de galería mock (HU-09). Simula "agregar foto" añadiendo una URL
/// de placeholder; la carga real a Cloud la hará el backend (RNF-06).
class _GalleryEditor extends StatelessWidget {
  const _GalleryEditor({
    required this.imageUrls,
    required this.enabled,
    required this.onChanged,
  });

  final List<String> imageUrls;
  final bool enabled;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Galería de imágenes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'La subida real a la nube se habilitará con el backend. Por '
          'ahora puedes simular fotos.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...imageUrls.asMap().entries.map(
              (entry) => Chip(
                avatar: const Icon(Icons.image_outlined, size: 18),
                label: Text('Foto ${entry.key + 1}'),
                onDeleted: enabled
                    ? () {
                        final next = List<String>.from(imageUrls)
                          ..removeAt(entry.key);
                        onChanged(next);
                      }
                    : null,
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Agregar foto'),
              onPressed: enabled
                  ? () {
                      final next = List<String>.from(imageUrls)
                        ..add('mock://foto-${imageUrls.length + 1}');
                      onChanged(next);
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
