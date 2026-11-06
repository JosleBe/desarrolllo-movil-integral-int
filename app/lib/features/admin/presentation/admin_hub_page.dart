import 'package:flutter/material.dart';

import 'audit_log_page.dart';
import 'incidences_page.dart';
import 'moderation_page.dart';
import 'user_management_page.dart';

/// Hub del módulo de Administración (Épica 5).
///
/// Agrupa las herramientas del Administrador: incidencias (HU-23),
/// usuarios y permisos (HU-24/25), bitácora (HU-26) y moderación (HU-27).
class AdminHubPage extends StatelessWidget {
  const AdminHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final options = <_AdminOption>[
      const _AdminOption(
        label: 'Incidencias',
        description: 'Revisar y resolver reportes',
        icon: Icons.report_problem_outlined,
        page: IncidencesPage(),
      ),
      const _AdminOption(
        label: 'Usuarios y permisos',
        description: 'Suspender o reactivar permisos',
        icon: Icons.manage_accounts_outlined,
        page: UserManagementPage(),
      ),
      const _AdminOption(
        label: 'Bitácora de auditoría',
        description: 'Historial de acciones críticas',
        icon: Icons.history,
        page: AuditLogPage(),
      ),
      const _AdminOption(
        label: 'Moderar catálogo',
        description: 'Pausar o retirar publicaciones',
        icon: Icons.gavel_outlined,
        page: ModerationPage(),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final option = options[index];
        return Card(
          child: ListTile(
            leading: Icon(option.icon),
            title: Text(option.label),
            subtitle: Text(option.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => option.page)),
          ),
        );
      },
    );
  }
}

class _AdminOption {
  const _AdminOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.page,
  });

  final String label;
  final String description;
  final IconData icon;
  final Widget page;
}
