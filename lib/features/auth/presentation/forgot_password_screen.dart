import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _successMessage;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _successMessage = null;
    });

    try {
      final message = await ref
          .read(authStateProvider.notifier)
          .forgotPassword(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _successMessage = message;
      });
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
      appBar: AppBar(title: const Text('Esqueci minha senha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Informe seu e-mail. Se existir uma conta, enviaremos um link para redefinir a senha.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (_successMessage != null) ...[
                  Icon(Icons.mark_email_read_outlined,
                      size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    _successMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Voltar ao login'),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'E-mail inválido' : null,
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
                        : const Text('Enviar link'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Voltar ao login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String authErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  return error.toString();
}
