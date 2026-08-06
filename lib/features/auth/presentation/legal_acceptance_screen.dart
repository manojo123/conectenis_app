import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/presentation/widgets/legal_links_text.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/auth/providers/legal_info_provider.dart';
import 'package:conectenis_app/shared/widgets/app_card.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

class LegalAcceptanceScreen extends ConsumerStatefulWidget {
  const LegalAcceptanceScreen({super.key});

  @override
  ConsumerState<LegalAcceptanceScreen> createState() => _LegalAcceptanceScreenState();
}

class _LegalAcceptanceScreenState extends ConsumerState<LegalAcceptanceScreen> {
  bool _accepted = false;
  bool _submitting = false;

  Future<void> _submit() async {
    if (!_accepted) {
      showToast(
          context, 'Aceite os Termos e a Política de Privacidade para continuar');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(authStateProvider.notifier).acceptLegalTerms();
      if (mounted && ref.read(authStateProvider).hasError) {
        showToast(
            context, authErrorMessage(ref.read(authStateProvider).error!));
      }
    } catch (e) {
      if (mounted) {
        showToast(context, authErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final legalAsync = ref.watch(legalInfoProvider);

    return Scaffold(
      body: SafeArea(
        child: legalAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            final fallback = LegalInfo.fromEnv();
            return _Body(
              termsUrl: fallback.termsUrl,
              privacyUrl: fallback.privacyUrl,
              accepted: _accepted,
              submitting: _submitting,
              onAcceptedChanged: (v) => setState(() => _accepted = v),
              onSubmit: _submit,
            );
          },
          data: (legal) => _Body(
            termsUrl: legal.termsUrl,
            privacyUrl: legal.privacyUrl,
            accepted: _accepted,
            submitting: _submitting,
            onAcceptedChanged: (v) => setState(() => _accepted = v),
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.termsUrl,
    required this.privacyUrl,
    required this.accepted,
    required this.submitting,
    required this.onAcceptedChanged,
    required this.onSubmit,
  });

  final String termsUrl;
  final String privacyUrl;
  final bool accepted;
  final bool submitting;
  final ValueChanged<bool> onAcceptedChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      padding: EdgeInsets.fromLTRB(24, 30, 24, screenBottomInset(context) + 24),
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.tintAcc,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Symbols.shield_rounded, size: 32, color: t.accentText),
        ),
        const SizedBox(height: 18),
        Text(
          'Termos e Privacidade',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: t.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Para usar o ConecTênis, é necessário aceitar os Termos de Uso e a Política de Privacidade.',
          style: TextStyle(fontSize: 14, color: t.muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Symbols.location_on_rounded,
                  size: 22, color: t.accentText),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'O aplicativo utiliza geolocalização para matchmaking regional. '
                  'Sua localização exata nunca é exibida a outros jogadores — detalhes na política.',
                  style:
                      TextStyle(fontSize: 13, color: t.muted, height: 1.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: accepted,
              activeColor: t.accent,
              checkColor: t.onAccent,
              onChanged: submitting ? null : (v) => onAcceptedChanged(v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LegalLinksText(
                  termsUrl: termsUrl,
                  privacyUrl: privacyUrl,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        LimeButton(
          label: 'Continuar',
          loading: submitting,
          glow: true,
          onPressed: submitting ? null : onSubmit,
        ),
      ],
    );
  }
}
