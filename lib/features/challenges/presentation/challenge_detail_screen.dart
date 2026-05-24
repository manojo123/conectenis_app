import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/challenge_status_chip.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/static_place_map.dart';
import 'package:conectenis_app/shared/utils/player_navigation.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';
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
          const SizedBox(height: 16),
          Text('Participantes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...c.participants.map(
            (p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(name: p.user.name, avatarUrl: p.user.avatarUrl),
              title: Text(p.user.name),
              subtitle: Text('NTRP ${p.user.ntrpRating.toStringAsFixed(1)} · ${p.status}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openPlayerProfile(context, ref, p.user.id),
            ),
          ),
          if (c.creator.id != 0 &&
              !c.participants.any((p) => p.user.id == c.creator.id)) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(name: c.creator.name, avatarUrl: c.creator.avatarUrl),
              title: Text(c.creator.name),
              subtitle: const Text('Criador'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openPlayerProfile(context, ref, c.creator.id),
            ),
          ],
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
              c.status != ChallengeStatus.declined)
            LimeButton(
              label: 'Cancelar desafio',
              outlined: true,
              danger: true,
              onPressed: _busy ? null : _confirmCancel,
            ),
          if (c.status == ChallengeStatus.accepted || c.status == ChallengeStatus.pendingScore)
            LimeButton(
              label: 'Avaliar desafio',
              onPressed: () => context.push('/challenges/${c.id}/evaluation'),
            ),
        ],
      ),
    );
  }
}
