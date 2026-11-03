import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/sentence.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_widgets.dart';

/// HU-01: "Hola, soy ___ y mi correo es ___@utez.edu.mx". El dominio es
/// parte fija de la frase; si alguien pega otro correo, se rechaza.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _matricula = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  AuthFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    _matricula.dispose();
    _password.dispose();
    _confirm.dispose();
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
      final user = await ref
          .read(authRepositoryProvider)
          .register(
            fullName: _name.text.trim(),
            email: AuthValidators.composeEmail(_matricula.text),
            password: _password.text,
          );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      context.go(AppRoutes.pendingFor(user.email));
    } on AuthFailure catch (f) {
      if (mounted) setState(() => _failure = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: SentenceScaffold(
          scene: Scene.green,
          busy: _busy,
          topAction: TextLink(
            'Ya tengo cuenta',
            onPressed: () => context.go(AppRoutes.login),
          ),
          action: ActionBar(
            label: 'Crear mi cuenta',
            busyLabel: 'Creando tu cuenta…',
            busy: _busy,
            onPressed: _submit,
          ),
          children: [
            if (failure != null) ...[
              Note(
                authFailureMessage(failure),
                action: failure is EmailAlreadyRegistered
                    ? TextLink(
                        'Entrar con esa cuenta',
                        onPressed: () => context.go(
                          AppRoutes.loginWith(
                            email: AuthValidators.composeEmail(_matricula.text),
                          ),
                        ),
                      )
                    : null,
              ),
              const Gap(1),
            ],
            const Say('Hola, soy'),
            SentenceField(
              key: const Key('register-name'),
              controller: _name,
              hint: 'tu nombre completo',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: AuthValidators.fullName,
            ),
            const Gap(1),
            const Say('y mi correo es'),
            MatriculaField(
              key: const Key('register-matricula'),
              controller: _matricula,
              validator: AuthValidators.institutionalLocal,
            ),
            const Gap(1),
            const Say('Mi clave será'),
            PasswordSentenceField(
              key: const Key('register-password'),
              controller: _password,
              hint: 'una clave nueva',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
              validator: AuthValidators.newPassword,
            ),
            const SizedBox(height: 12),
            PasswordRulesLine(password: _password.text),
            const Gap(1),
            const Say('y la repito'),
            PasswordSentenceField(
              key: const Key('register-confirm'),
              controller: _confirm,
              hint: 'otra vez',
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _submit(),
              validator: (v) =>
                  AuthValidators.passwordConfirmation(v, _password.text),
            ),
            const Gap(1.4),
            const Aside(
              'Solo para alumnos y personal de la UTEZ. Te mandaremos un enlace para activar tu cuenta.',
            ),
          ],
        ),
      ),
    );
  }
}
