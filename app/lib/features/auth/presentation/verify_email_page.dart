import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/router/app_router.dart';
import 'providers/auth_controller.dart';

/// Argumentos para la pantalla de verificación.
class VerifyArgs {
  const VerifyArgs({required this.email, this.devToken});

  final String email;

  /// Token mostrado solo en desarrollo (en producción llega por correo).
  final String? devToken;
}

/// Verificación del correo por token (HU-02).
///
/// Permite confirmar la cuenta con el token, reenviar uno nuevo si venció
/// o ya se usó, y al verificar regresa al login para iniciar sesión.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({required this.args, super.key});

  final VerifyArgs args;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final _tokenController = TextEditingController();
  String? _devToken;

  @override
  void initState() {
    super.initState();
    // Con el backend real el código solo llega por correo (devToken vacío).
    _devToken = _nonEmpty(widget.args.devToken);
    // En desarrollo, pre-rellena el token para agilizar la prueba.
    if (Env.isDev && _devToken != null) {
      _tokenController.text = _devToken!;
    }
  }

  static String? _nonEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyEmail(email: widget.args.email, token: _tokenController.text);

    if (!mounted) return;
    if (ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Cuenta verificada. Ya puedes iniciar sesión.'),
          ),
        );
      router.go(AppRoutes.login);
    } else {
      final message = ref.read(authControllerProvider).errorMessage;
      if (message != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _resend() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await ref
          .read(authRepositoryProvider)
          .resendVerificationToken(email: widget.args.email);
      if (!mounted) return;
      setState(() {
        _devToken = _nonEmpty(token);
        if (Env.isDev && _devToken != null) _tokenController.text = token;
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Te enviamos un nuevo código.')),
        );
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('AuthException: ', '');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifica tu correo')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enviamos un código de verificación a:',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.args.email,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  if (Env.isDev && _devToken != null)
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Modo desarrollo — código: $_devToken',
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    keyboardType: TextInputType.number,
                    enabled: !state.isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Código de verificación',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: state.isLoading ? null : _verify,
                    child: state.isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verificar'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.isLoading ? null : _resend,
                    child: const Text('Reenviar código'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
