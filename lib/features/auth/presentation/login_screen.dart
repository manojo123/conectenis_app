import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/widgets/app_switch.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/brand_logo.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';
import 'package:conectenis_app/shared/widgets/theme_toggle_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    if (Env.googleOAuthWebClientId.isEmpty) {
      showToast(
        context,
        'Configure GOOGLE_OAUTH_WEB_CLIENT_ID no .env (docs/GOOGLE_SIGNIN.md)',
      );
      return;
    }

    await ref.read(authStateProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.hasError) {
      showToast(context, authErrorMessage(state.error!));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authStateProvider.notifier)
        .login(_email.text.trim(), _password.text);
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.hasError) {
      showToast(context, authErrorMessage(state.error!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final t = context.t;

    return Scaffold(
      body: Stack(
        children: [
          // Prototype backdrop: soft lime radial glow at the top-right corner.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.9, -1.05),
                  radius: 1.2,
                  colors: [
                    t.accent.withValues(alpha: 0.16),
                    t.accent.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [ThemeToggleButton()],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 18),
                          const Center(
                            child: BrandLogo(
                              variant: BrandLogoVariant.horizontal,
                              height: 56,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              'Conecte-se. Desafie. Jogue.',
                              style: TextStyle(
                                fontSize: 14,
                                letterSpacing: 0.2,
                                color: t.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'E-mail',
                              prefixIcon: Icon(Symbols.mail_rounded, size: 20),
                            ),
                            validator: (v) => v != null && v.contains('@')
                                ? null
                                : 'E-mail inválido',
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
                            validator: (v) => v != null && v.length >= 8
                                ? null
                                : 'Mínimo 8 caracteres',
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    setState(() => _remember = !_remember),
                                child: Row(
                                  children: [
                                    AppSwitch(
                                      value: _remember,
                                      onChanged: (v) =>
                                          setState(() => _remember = v),
                                    ),
                                    const SizedBox(width: 9),
                                    Text(
                                      'Manter conectado',
                                      style: TextStyle(
                                          fontSize: 13, color: t.muted),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => context.push('/forgot-password'),
                                child: Text(
                                  'Esqueci a senha',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: t.accentText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          LimeButton(
                            label: 'Entrar',
                            loading: auth.isLoading,
                            glow: true,
                            onPressed: auth.isLoading ? null : _submit,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: Divider(color: t.border)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'ou continue com',
                                  style: TextStyle(
                                      fontSize: 12, color: t.disabled),
                                ),
                              ),
                              Expanded(child: Divider(color: t.border)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _SocialButton(
                                  label: 'Google',
                                  leading: Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: t.accentText,
                                    ),
                                  ),
                                  onTap:
                                      auth.isLoading ? null : _loginWithGoogle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SocialButton(
                                  label: 'Apple',
                                  leading: Icon(Icons.apple,
                                      size: 20, color: t.text),
                                  onTap: auth.isLoading
                                      ? null
                                      : () => showToast(context,
                                          'Login com Apple em breve'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/register'),
                    child: Text.rich(
                      TextSpan(
                        text: 'Não tem conta? ',
                        style: TextStyle(fontSize: 14, color: t.muted),
                        children: [
                          TextSpan(
                            text: 'Cadastre-se grátis',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: t.accentText,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PressableScale(
      onTap: onTap,
      enabled: onTap != null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
