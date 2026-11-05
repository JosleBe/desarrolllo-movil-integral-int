import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import 'providers/auth_controller.dart';
import 'verify_email_page.dart';

/// Registro con correo institucional (HU-01).
///
/// Valida el dominio @utez.edu.mx en la UI y delega la creación de la
/// cuenta al repositorio. Tras registrar, lleva a la verificación por
/// token (HU-02).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final repository = ref.read(authRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final result = await repository.register(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      router.push(
        AppRoutes.verify,
        extra: VerifyArgs(
          email: result.user.email,
          devToken: result.devToken,
        ),
      );
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('AuthException: ', '');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      enabled: !_submitting,
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Correo institucional',
                        helperText: 'Debe terminar en @utez.edu.mx',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (!email.endsWith('@utez.edu.mx')) {
                          return 'Usa tu correo @utez.edu.mx';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Mínimo 8 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                      ),
                      validator: (value) => value != _passwordController.text
                          ? 'Las contraseñas no coinciden'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Registrarme'),
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
