import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/sentence.dart';
import '../data/auth_repository.dart';
import '../data/fake_auth_repository.dart';
import '../domain/auth_models.dart';
import '../domain/auth_validators.dart';
import 'session_controller.dart';
import 'widgets/auth_widgets.dart';

/// HU-03: "Soy ___@utez.edu.mx y mi clave es ___". Ante credenciales
/// incorrectas hay un solo mensaje, sin decir qué dato falló.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final _matricula = TextEditingController(
    text: widget.initialEmail?.split('@').first,
  );
  final _password = TextEditingController();
  bool _busy = false;
  AuthFailure? _failure;

  @override
  void dispose() {
    _matricula.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .signIn(
            email: AuthValidators.composeEmail(_matricula.text),
            password: _password.text,
          );
      // El router lleva al inicio cuando cambia la sesión.
    } on AuthFailure catch (f) {
      if (!mounted) return;
      _password.clear();
      setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final expired =
        session is SignedOut && session.reason == SignOutReason.expired;
    final isDemo = ref.watch(authRepositoryProvider) is FakeAuthRepository;
    final failure = _failure;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: SentenceScaffold(
          scene: Scene.mint,
          busy: _busy,
          topAction: TextLink(
            'Soy nuevo',
            onPressed: () => context.go(AppRoutes.register),
          ),
          action: ActionBar(
            label: 'Entrar',
            busyLabel: 'Entrando…',
            busy: _busy,
            onPressed: _submit,
          ),
          children: [
            if (expired && failure == null) ...[
              const Note('Tu sesión venció. Entra de nuevo.'),
              const Gap(1),
            ],
            if (failure != null) ...[
              Note(
                authFailureMessage(failure),
                action: failure is EmailNotVerified
                    ? TextLink(
                        'Mándame el enlace otra vez',
                        onPressed: () =>
                            context.go(AppRoutes.pendingFor(failure.email)),
                      )
                    : null,
              ),
              const Gap(1),
            ],
            const Say('Soy'),
            MatriculaField(
              key: const Key('login-matricula'),
              controller: _matricula,
              validator: AuthValidators.institutionalLocal,
            ),
            const Gap(1),
            const Say('y mi clave es'),
            PasswordSentenceField(
              key: const Key('login-password'),
              controller: _password,
              onSubmitted: (_) => _submit(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Falta tu clave.' : null,
            ),
            const Gap(1.4),
            const Aside(
              'Calculadoras, batas, kits de dibujo: rentas lo que te falta a alguien del campus.',
            ),
            if (isDemo) ...[
              const SizedBox(height: 12),
              const Aside('Modo demo: entra como demo con la clave Demo1234.'),
            ],
          ],
        ),
      ),
    );
  }
}
