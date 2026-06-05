import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/app_snackbar.dart';
import 'package:conectenis_app/shared/widgets/challenge_participants_versus.dart';
import 'package:conectenis_app/shared/widgets/challenge_result_section.dart';
import 'package:conectenis_app/shared/widgets/challenge_status_chip.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/static_place_map.dart';
import 'package:intl/intl.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  ConsumerState<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen> {
  Challenge? _challenge;
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await ref.read(challengesRepositoryProvider).byId(widget.challengeId);
      setState(() {
        _challenge = c;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      bumpChallengesRefresh(ref);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approveResult() async {
    setState(() => _busy = true);
    try {
      await ref.read(challengesRepositoryProvider).approveResult(widget.challengeId);
      bumpChallengesRefresh(ref);
      await _load();
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Aprovação registrada.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showDanger(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar desafio'),
        content: const Text('Tem certeza que deseja cancelar este desafio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancelar desafio')),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => ref.read(challengesRepositoryProvider).cancel(_challenge!.id));
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingView());
    if (_error != null || _challenge == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: _error ?? 'Desafio não encontrado', onRetry: _load),
      );
    }

    final c = _challenge!;
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final isCreator = c.role == 'created';
    final currentUserId = ref.watch(authStateProvider).value?.id ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Desafio')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.status.label, style: Theme.of(context).textTheme.headlineSmall),
              ),
              ChallengeStatusChip(status: c.status),
            ],
          ),
          const SizedBox(height: 8),
          Text('${c.format.label} · ${c.type.label}'),
          Text(df.format(c.scheduledStart)),
          if (c.hasProposedResult) ...[
            const SizedBox(height: 16),
            ChallengeResultSection(challenge: c, currentUserId: currentUserId),
          ],
          const SizedBox(height: 16),
          Text('Participantes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ChallengeParticipantsVersus(challenge: c),
          if (c.participants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: c.participants.map((p) {
                  return Chip(
                    label: Text('${p.user.name.split(' ').first}: ${p.status}'),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
          if (c.place != null) ...[
            const Divider(height: 32),
            Text('Local', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place),
              title: Text(c.place!.name),
              subtitle: Text(c.place!.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/places/${c.place!.id}'),
            ),
            const SizedBox(height: 8),
            StaticPlaceMap(
              latitude: c.place!.latitude,
              longitude: c.place!.longitude,
            ),
          ],
          const SizedBox(height: 24),
          if (c.status == ChallengeStatus.pendingAcceptance && c.role == 'received') ...[
            LimeButton(
              label: 'Aceitar',
              onPressed: _busy ? null : () => _run(() => ref.read(challengesRepositoryProvider).accept(c.id)),
            ),
            const SizedBox(height: 8),
            LimeButton(
              label: 'Recusar',
              outlined: true,
              onPressed: _busy ? null : () => _run(() => ref.read(challengesRepositoryProvider).decline(c.id)),
            ),
          ],
          if (c.status == ChallengeStatus.pendingCandidates && c.role != 'created')
            LimeButton(
              label: 'Candidatar-se',
              onPressed: _busy ? null : () => _run(() => ref.read(challengesRepositoryProvider).apply(c.id)),
            ),
          if (isCreator &&
              c.status != ChallengeStatus.cancelled &&
              c.status != ChallengeStatus.completed &&
              c.status != ChallengeStatus.declined &&
              c.status != ChallengeStatus.pendingResultApproval)
            LimeButton(
              label: 'Cancelar desafio',
              outlined: true,
              danger: true,
              onPressed: _busy ? null : _confirmCancel,
            ),
          if (c.canSubmitResult)
            LimeButton(
              label: 'Informar resultado',
              onPressed: _busy ? null : () => context.push('/challenges/${c.id}/evaluation'),
            ),
          if (c.canApproveResult) ...[
            const SizedBox(height: 8),
            LimeButton(
              label: 'Aprovar resultado',
              loading: _busy,
              onPressed: _busy ? null : _approveResult,
            ),
          ],
          if (c.status == ChallengeStatus.completed)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Resultado confirmado por todos. Não é possível alterar o placar.',
                style: TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
