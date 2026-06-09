import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/presentation/widgets/legal_links_text.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/auth/providers/legal_info_provider.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os Termos e a Política de Privacidade para continuar')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(authStateProvider.notifier).acceptLegalTerms();
      if (mounted && ref.read(authStateProvider).hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(ref.read(authStateProvider).error!))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final legalAsync = ref.watch(legalInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Termos e Privacidade')),
      body: legalAsync.when(
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
    return ListView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
      children: [
        Text(
          'Conformidade LGPD',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Para usar o ConecTenis, é necessário aceitar os Termos de Uso e a Política de Privacidade. '
          'O aplicativo utiliza geolocalização para matchmaking regional — detalhes estão na política.',
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: accepted,
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
        const SizedBox(height: 32),
        LimeButton(
          label: 'Continuar',
          loading: submitting,
          onPressed: submitting ? null : onSubmit,
        ),
      ],
    );
  }
}
