import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../admin/presentation/admin_hub_page.dart';
import '../../catalog/presentation/catalog_page.dart';
import '../../catalog/presentation/my_listings_page.dart';
import '../../rentals/presentation/my_bookings_page.dart';
import '../../rentals/presentation/my_rentals_page.dart';

/// Pantalla principal tras iniciar sesión.
///
/// Muestra navegación condicional según los permisos de la cuenta (HU-05):
/// - Catálogo: siempre visible (Usuario Base).
/// - Mis publicaciones y Mis rentas: solo con permiso Vendedor.
/// El Rentador sin Vendedor solo ve el catálogo; el perfil restringido
/// (sin permisos) también navega el catálogo e historial.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final isSeller = user?.permissions.seller ?? false;
    final isRenter = user?.permissions.renter ?? false;
    final isAdmin = user?.permissions.admin ?? false;

    // Construye las secciones visibles según permisos.
    final destinations = <_Section>[
      const _Section(
        label: 'Catálogo',
        shortLabel: 'Catálogo',
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront,
        page: CatalogPage(),
      ),
      if (isRenter)
        const _Section(
          label: 'Mis solicitudes',
          shortLabel: 'Pedidos',
          icon: Icons.shopping_bag_outlined,
          selectedIcon: Icons.shopping_bag,
          page: MyBookingsPage(),
        ),
      if (isSeller) ...[
        const _Section(
          label: 'Mis publicaciones',
          shortLabel: 'Publicar',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          page: MyListingsPage(),
        ),
        const _Section(
          label: 'Mis rentas',
          shortLabel: 'Rentas',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          page: MyRentalsPage(),
        ),
      ],
      if (isAdmin)
        const _Section(
          label: 'Admin',
          shortLabel: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          page: AdminHubPage(),
        ),
    ];

    // Evita índice fuera de rango si cambian los permisos.
    final safeIndex = _index.clamp(0, destinations.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(destinations[safeIndex].label),
        actions: [
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: destinations[safeIndex].page,
      bottomNavigationBar: destinations.length > 1
          ? NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => setState(() => _index = i),
              // Con muchas secciones, muestra la etiqueta solo en la
              // seleccionada para que no se encimen en pantallas angostas.
              labelBehavior: destinations.length > 4
                  ? NavigationDestinationLabelBehavior.onlyShowSelected
                  : NavigationDestinationLabelBehavior.alwaysShow,
              destinations: destinations
                  .map(
                    (s) => NavigationDestination(
                      icon: Icon(s.icon),
                      selectedIcon: Icon(s.selectedIcon),
                      label: s.shortLabel,
                      tooltip: s.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }
}

class _Section {
  const _Section({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String label;

  /// Etiqueta corta para la barra de navegación (evita que se encimen).
  final String shortLabel;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}
