import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).register(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
          _passwordConfirmation.text,
        );
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(state.error!))),
      );
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'E-mail inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Cadastrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
