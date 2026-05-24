import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
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
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
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

    return Scaffold(
      appBar: AppBar(title: const Text('Desafio')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(c.status.label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${c.format.label} · ${c.type.label}'),
          Text(df.format(c.scheduledStart)),
          if (c.place != null) Text('Local: ${c.place!.name}'),
          const SizedBox(height: 16),
          ...c.participants.map(
            (p) => ListTile(
              leading: CircleAvatar(child: Text(p.user.name.isNotEmpty ? p.user.name[0] : '?')),
              title: Text(p.user.name),
              subtitle: Text('NTRP ${p.user.ntrpRating.toStringAsFixed(1)} · ${p.status}'),
            ),
          ),
          const SizedBox(height: 24),
          if (c.status == ChallengeStatus.pendingAcceptance && c.role == 'received') ...[
            LimeButton(label: 'Aceitar', onPressed: _busy ? null : () => _run(() => ref.read(challengesRepositoryProvider).accept(c.id))),
            const SizedBox(height: 8),
            LimeButton(label: 'Recusar', outlined: true, onPressed: _busy ? null : () => _run(() => ref.read(challengesRepositoryProvider).decline(c.id))),
          ],
          if (c.status == ChallengeStatus.pendingCandidates && c.role != 'created')
            LimeButton(label: 'Candidatar-se', onPressed: _busy ? null : () => _run(() => ref.read(challengesRepositoryProvider).apply(c.id))),
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
