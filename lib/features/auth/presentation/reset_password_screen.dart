import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.email,
  });

  final String token;
  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.token.isEmpty || widget.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link inválido. Solicite um novo link de redefinição.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final message = await ref.read(authStateProvider.notifier).resetPassword(
            token: widget.token,
            email: widget.email,
            password: _password.text,
            passwordConfirmation: _passwordConfirmation.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova senha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Defina uma nova senha para ${widget.email}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  validator: (v) =>
                      v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordConfirmation,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmar senha'),
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'Mínimo 8 caracteres';
                    }
                    if (v != _password.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Redefinir senha'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
