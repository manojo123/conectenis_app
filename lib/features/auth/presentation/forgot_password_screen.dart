import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';

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
            const ScreenHeader(title: 'Esqueci a senha'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_successMessage != null) ...[
                        const SizedBox(height: 26),
                        Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.tintSucc,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(Symbols.mark_email_read_rounded,
                              size: 34, color: t.success),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _successMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14.5, color: t.text, height: 1.5),
                        ),
                        const SizedBox(height: 26),
                        LimeButton(
                          label: 'Voltar ao login',
                          outlined: true,
                          onPressed: () => context.go('/login'),
                        ),
                      ] else ...[
                        Text(
                          'Informe seu e-mail. Se existir uma conta, enviaremos um link para redefinir a senha.',
                          style: TextStyle(
                              fontSize: 14, color: t.muted, height: 1.5),
                        ),
                        const SizedBox(height: 22),
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
                        const SizedBox(height: 22),
                        LimeButton(
                          label: 'Enviar link',
                          glow: true,
                          loading: _loading,
                          onPressed: _loading ? null : _submit,
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.go('/login'),
                            child: Text(
                              'Voltar ao login',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: t.accentText,
                              ),
                            ),
                          ),
                        ),
                      ],
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

String authErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  return error.toString();
}
