import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';

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
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.token.isEmpty || widget.email.isEmpty) {
      showToast(context, 'Link inválido. Solicite um novo link de redefinição.');
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
      showToast(context, message);
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Nova senha',
              onBack: () => context.go('/login'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Defina uma nova senha para ${widget.email}',
                        style:
                            TextStyle(fontSize: 14, color: t.muted, height: 1.5),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'Nova senha',
                          prefixIcon:
                              const Icon(Symbols.lock_rounded, size: 20),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Symbols.visibility_rounded
                                  : Symbols.visibility_off_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 8
                            ? 'Mínimo 8 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordConfirmation,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          hintText: 'Confirmar senha',
                          prefixIcon: Icon(Symbols.lock_rounded, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Mínimo 8 caracteres';
                          }
                          if (v != _password.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      LimeButton(
                        label: 'Redefinir senha',
                        glow: true,
                        loading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
