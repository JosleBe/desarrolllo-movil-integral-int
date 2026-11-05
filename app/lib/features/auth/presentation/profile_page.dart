import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/presentation/my_listings_page.dart';
import '../../rentals/presentation/my_bookings_page.dart';
import '../domain/user_permissions.dart';
import 'providers/auth_controller.dart';

/// Gestión de perfil (HU-04).
///
/// Permite editar datos de contacto (nombre, teléfono) pero no el correo
/// institucional. Muestra los permisos de la cuenta y, si el perfil está
/// restringido (sin permisos activos), lo indica en modo solo lectura.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          fullName: _nameController.text,
          phone: _phoneController.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Perfil actualizado' : 'No se pudo actualizar el perfil',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final restricted = user.permissions.isRestricted;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
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
                    if (restricted) const _RestrictedBanner(),
                    _PermissionsCard(permissions: user.permissions),
                    const SizedBox(height: 16),
                    _HistoryCard(permissions: user.permissions),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: user.email,
                      readOnly: true,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo institucional',
                        helperText: 'El correo no se puede modificar',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      enabled: !_saving && !restricted,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Ingresa tu nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_saving && !restricted,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono de contacto',
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!restricted)
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar cambios'),
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

class _RestrictedBanner extends StatelessWidget {
  const _RestrictedBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Perfil restringido: solo lectura. No tienes permisos de '
                'Rentador ni Vendedor activos.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({required this.permissions});

  final UserPermissions permissions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permisos de la cuenta',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _PermissionRow(label: 'Rentador', active: permissions.renter),
            _PermissionRow(label: 'Vendedor', active: permissions.seller),
          ],
        ),
      ),
    );
  }
}

/// Historial general del usuario (HU-04): accesos a sus rentas y
/// publicaciones con su estado. Se muestra siempre, incluso con permisos
/// inactivos, para permitir la consulta en modo solo lectura.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.permissions});

  final UserPermissions permissions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mi historial',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Consulta tus rentas y publicaciones con su estado actual.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Mis solicitudes de renta'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyBookingsPage(),
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Mis publicaciones'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyListingsPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            color: active ? scheme.primary : scheme.outline,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            active ? 'Activo' : 'Inactivo',
            style: TextStyle(
              color: active ? scheme.primary : scheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
