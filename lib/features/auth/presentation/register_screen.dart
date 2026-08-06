import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/presentation/widgets/legal_links_text.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/auth/providers/legal_info_provider.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';

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
  bool _termsAccepted = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_termsAccepted) {
      showToast(context, 'Aceite os Termos e a Política de Privacidade');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).register(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
          _passwordConfirmation.text,
          termsAccepted: true,
        );
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.hasError) {
      showToast(context, authErrorMessage(state.error!));
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final legalAsync = ref.watch(legalInfoProvider);
    final legal = legalAsync.value ?? LegalInfo.fromEnv();
    final t = context.t;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Criar conta'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crie sua conta grátis e encontre parceiros de jogo do seu nível.',
                        style: TextStyle(
                            fontSize: 14, color: t.muted, height: 1.5),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Nome completo',
                          prefixIcon: Icon(Symbols.person_rounded, size: 20),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Informe seu nome' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'E-mail',
                          prefixIcon: Icon(Symbols.mail_rounded, size: 20),
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'E-mail inválido'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'Senha',
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
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _termsAccepted,
                            activeColor: t.accent,
                            checkColor: t.onAccent,
                            onChanged: auth.isLoading
                                ? null
                                : (v) => setState(
                                    () => _termsAccepted = v ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: LegalLinksText(
                                termsUrl: legal.termsUrl,
                                privacyUrl: legal.privacyUrl,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      LimeButton(
                        label: 'Cadastrar',
                        glow: true,
                        loading: auth.isLoading,
                        onPressed: auth.isLoading ? null : _submit,
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
