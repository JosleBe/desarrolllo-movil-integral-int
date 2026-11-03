import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/sentence.dart';
import '../../auth/presentation/session_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    await ref.read(sessionControllerProvider.notifier).signOut();
    // El router lleva a la pantalla de entrada cuando cambia la sesión.
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    if (session is! SignedIn) return const SizedBox.shrink();
    final user = session.user;
    final until = TimeOfDay.fromDateTime(
      session.expiresAt.toLocal(),
    ).format(context);

    return SentenceScaffold(
      scene: Scene.mint,
      busy: _signingOut,
      action: ActionBar(
        label: 'Cerrar sesión',
        busyLabel: 'Cerrando sesión…',
        busy: _signingOut,
        onPressed: _signOut,
      ),
      children: [
        Say.rich([
          const TextSpan(text: 'Hola, '),
          you(user.firstName),
          const TextSpan(text: '.'),
        ]),
        const Gap(0.6),
        Say.rich([
          const TextSpan(text: 'Tu sesión segura dura hasta las '),
          you(until),
          const TextSpan(text: '.'),
        ]),
        const Gap(1.2),
        Aside(
          'Entraste como ${user.email}. Aquí vas a encontrar los útiles que la comunidad tiene para rentar.',
        ),
      ],
    );
  }
}
