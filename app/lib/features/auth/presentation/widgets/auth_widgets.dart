import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/sentence.dart';
import '../../data/auth_repository.dart';
import '../../data/fake_auth_repository.dart';
import '../../domain/auth_models.dart';
import '../../domain/auth_validators.dart';

/// Mensaje para cada [AuthFailure]: qué pasó y qué hacer, en la voz de la app.
String authFailureMessage(AuthFailure failure) => switch (failure) {
  InstitutionalEmailRequired() => AuthValidators.domainMessage,
  EmailAlreadyRegistered() =>
    'Ya hay una cuenta con ese correo. Entra con ella.',
  InvalidCredentials() => 'Ese correo o esa clave no coinciden.',
  EmailNotVerified() =>
    'Tu cuenta todavía no está activa. Abre el enlace que te mandamos.',
  VerificationTokenExpired() => 'Pide uno nuevo y ábrelo antes de 24 horas.',
  VerificationTokenAlreadyUsed() =>
    'Cada enlace sirve una sola vez. Si tu cuenta no quedó activa, pide otro.',
  VerificationTokenInvalid() =>
    'Copia el enlace completo del correo o pide uno nuevo.',
  TooManyRequests() => 'Ya te mandamos uno hace poco. Espera un minuto.',
  SessionExpired() => 'Tu sesión terminó. Entra de nuevo.',
  NetworkFailure() =>
    'No hay conexión con el servidor. Revisa tu internet y vuelve a intentarlo.',
  UnexpectedFailure() =>
    'Algo falló de nuestro lado. Vuelve a intentarlo en unos minutos.',
};

/// Requisitos de la clave como una frase: cada parte se enciende al cumplirse.
class PasswordRulesLine extends StatelessWidget {
  const PasswordRulesLine({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final style = SceneStyle.of(context);
    final rules = AuthValidators.passwordRules(password);
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('con', style: style.body),
        for (final rule in rules)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                rule.met ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: rule.met ? style.colors.user : style.colors.faded,
                semanticLabel: rule.met ? 'cumple' : 'falta',
              ),
              const SizedBox(width: 5),
              Text(
                rule.label,
                style: style.body.copyWith(
                  fontWeight: rule.met ? FontWeight.w700 : FontWeight.w400,
                  color: rule.met ? style.colors.user : style.colors.faded,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Reenvío del enlace de verificación (HU-02). Si no conocemos el correo, lo
/// pide como parte de la frase. Respeta un tiempo de espera entre envíos.
class ResendVerification extends ConsumerStatefulWidget {
  const ResendVerification({
    super.key,
    this.email,
    this.label = 'Mándame otro enlace',
    this.onSent,
    this.cooldown = const Duration(seconds: 60),
  });

  final String? email;
  final String label;
  final VoidCallback? onSent;
  final Duration cooldown;

  @override
  ConsumerState<ResendVerification> createState() => _ResendVerificationState();
}

class _ResendVerificationState extends ConsumerState<ResendVerification> {
  final _formKey = GlobalKey<FormState>();
  final _matricula = TextEditingController();
  bool _busy = false;
  String? _sentTo;
  AuthFailure? _failure;
  int _secondsLeft = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _matricula.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _ticker?.cancel();
    setState(() => _secondsLeft = widget.cooldown.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    if (!_formKey.currentState!.validate()) return;
    final email = widget.email ?? AuthValidators.composeEmail(_matricula.text);
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(authRepositoryProvider).resendVerification(email);
      if (!mounted) return;
      setState(() => _sentTo = email);
      _startCooldown();
      widget.onSent?.call();
    } on AuthFailure catch (f) {
      if (!mounted) return;
      setState(() => _failure = f);
      if (f is TooManyRequests) _startCooldown();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _secondsLeft > 0;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.email == null) ...[
            const Say('Mi correo es'),
            MatriculaField(
              key: const Key('resend-matricula'),
              controller: _matricula,
              validator: AuthValidators.institutionalLocal,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _resend(),
            ),
            const Gap(0.6),
          ],
          if (_sentTo != null) ...[
            Note(
              'Listo: va en camino un enlace nuevo a $_sentTo. Los anteriores ya no sirven.',
            ),
            const SizedBox(height: 8),
          ],
          if (_failure != null) ...[
            Note(authFailureMessage(_failure!)),
            const SizedBox(height: 8),
          ],
          TextLink(
            _busy
                ? 'Mandando…'
                : waiting
                ? 'Puedes pedir otro en $_secondsLeft s'
                : widget.label,
            onPressed: _busy || waiting ? null : _resend,
          ),
        ],
      ),
    );
  }
}

/// Solo en modo demo: sin servidor de correo, el enlace se ofrece aquí.
class DemoOutbox extends ConsumerWidget {
  const DemoOutbox({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(authRepositoryProvider);
    if (repo is! FakeAuthRepository) return const SizedBox.shrink();
    final mail = repo.lastEmailTo(email);
    if (mail == null) return const SizedBox.shrink();
    final style = SceneStyle.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: style.colors.faded, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modo demo: no hay servidor de correo, así que el enlace está aquí.',
            style: style.body.copyWith(color: style.colors.faded),
          ),
          TextLink(
            'Abrir el enlace del correo',
            onPressed: () => context.go(AppRoutes.verifyWith(mail.token)),
          ),
          TextLink(
            'Abrirlo como si ya hubiera vencido',
            onPressed: () {
              repo.debugExpireVerificationTokens(mail.to);
              context.go(AppRoutes.verifyWith(mail.token));
            },
          ),
        ],
      ),
    );
  }
}
