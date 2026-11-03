import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/sentence.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';
import 'widgets/auth_widgets.dart';

/// HU-02: destino del enlace del correo (`/verificar?token=...`).
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  late Future<AuthUser> _result = _verify();

  @override
  void didUpdateWidget(VerifyEmailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) _result = _verify();
  }

  Future<AuthUser> _verify() {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      return Future.error(const VerificationTokenInvalid());
    }
    return ref.read(authRepositoryProvider).verifyEmail(token);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser>(
      future: _result,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SentenceScaffold(
            scene: Scene.indigo,
            busy: true,
            children: [Say('Revisando tu enlace…')],
          );
        }
        if (snapshot.hasData) return _Verified(user: snapshot.data!);
        final error = snapshot.error;
        return _Rejected(
          failure: error is AuthFailure ? error : const UnexpectedFailure(),
        );
      },
    );
  }
}

class _Verified extends StatelessWidget {
  const _Verified({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return SentenceScaffold(
      scene: Scene.green,
      action: ActionBar(
        label: 'Entrar a SRUU',
        onPressed: () => context.go(AppRoutes.loginWith(email: user.email)),
      ),
      children: [
        Say.rich([
          const TextSpan(text: 'Listo, '),
          you(user.firstName),
          const TextSpan(text: '.'),
        ]),
        const Gap(0.6),
        Say.rich([
          const TextSpan(text: 'Tu cuenta está '),
          you('verificada'),
          const TextSpan(text: ' y tu rol es '),
          you('Usuario Base'),
          const TextSpan(text: '.'),
        ]),
        const Gap(1.2),
        Aside(
          'Confirmamos que ${user.email} es tuyo. Ya puedes explorar el catálogo; los permisos para rentar o publicar se activan aparte.',
        ),
      ],
    );
  }
}

class _Rejected extends StatefulWidget {
  const _Rejected({required this.failure});

  final AuthFailure failure;

  @override
  State<_Rejected> createState() => _RejectedState();
}

class _RejectedState extends State<_Rejected> {
  @override
  Widget build(BuildContext context) {
    final failure = widget.failure;
    final (headline, email) = switch (failure) {
      VerificationTokenExpired(:final email) => (
        'Ese enlace ya venció.',
        email,
      ),
      VerificationTokenAlreadyUsed(:final email) => (
        'Ese enlace ya se usó.',
        email,
      ),
      VerificationTokenInvalid() => ('Ese enlace no es válido.', null),
      _ => ('No pudimos revisar tu enlace.', null),
    };

    return SentenceScaffold(
      scene: Scene.red,
      topAction: TextLink(
        'Volver a entrar',
        onPressed: () => context.go(AppRoutes.loginWith(email: email)),
      ),
      children: [
        Say(headline),
        const Gap(0.6),
        Aside(authFailureMessage(failure)),
        const Gap(1),
        ResendVerification(
          email: email,
          label: 'Mándame uno nuevo',
          onSent: () => setState(() {}),
        ),
        if (email != null) DemoOutbox(email: email),
      ],
    );
  }
}
