import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/sentence.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_widgets.dart';

/// HU-01 → HU-02: la cuenta existe y espera que se abra el enlace del correo.
class VerificationPendingPage extends StatefulWidget {
  const VerificationPendingPage({super.key, this.email});

  final String? email;

  @override
  State<VerificationPendingPage> createState() =>
      _VerificationPendingPageState();
}

class _VerificationPendingPageState extends State<VerificationPendingPage> {
  final _linkFormKey = GlobalKey<FormState>();
  final _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _openPastedLink() {
    if (!_linkFormKey.currentState!.validate()) return;
    final token = AuthValidators.extractVerificationToken(_link.text)!;
    context.go(AppRoutes.verifyWith(token));
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email;

    return SentenceScaffold(
      scene: Scene.indigo,
      topAction: TextLink(
        'Volver a entrar',
        onPressed: () => context.go(AppRoutes.loginWith(email: email)),
      ),
      action: email == null
          ? null
          : ActionBar(
              label: 'Ya lo abrí, entrar',
              onPressed: () => context.go(AppRoutes.loginWith(email: email)),
            ),
      children: [
        if (email != null) ...[
          Say.rich([
            const TextSpan(text: 'Te mandamos un enlace a '),
            you(email),
            const TextSpan(text: '.'),
          ]),
          const Gap(0.8),
          const Aside(
            'Tu cuenta está pendiente de verificación. Abre el enlace antes de 24 horas para activarla; cada enlace sirve una sola vez.',
          ),
          const Gap(0.6),
          ResendVerification(
            email: email,
            label: '¿No llegó? Mándamelo otra vez',
            onSent: () => setState(() {}),
          ),
        ] else ...[
          const Say('Te mandamos un enlace nuevo para activar tu cuenta.'),
          const Gap(1),
          const ResendVerification(label: 'Mándame el enlace'),
        ],
        const Gap(1.4),
        const Aside('¿Lo abriste en otro dispositivo? Pega aquí el enlace:'),
        const SizedBox(height: 6),
        Form(
          key: _linkFormKey,
          child: SentenceField(
            key: const Key('pasted-link'),
            controller: _link,
            hint: 'enlace del correo',
            scale: 0.55,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _openPastedLink(),
            validator: (v) =>
                AuthValidators.extractVerificationToken(v ?? '') == null
                ? 'Pega el enlace completo que llegó a tu correo.'
                : null,
          ),
        ),
        TextLink('Verificar con este enlace', onPressed: _openPastedLink),
        if (email != null) DemoOutbox(email: email),
      ],
    );
  }
}
