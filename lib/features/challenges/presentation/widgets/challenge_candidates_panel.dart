import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';

class ChallengeCandidatesPanel extends ConsumerStatefulWidget {
  const ChallengeCandidatesPanel({
    super.key,
    required this.challengeId,
    required this.onChanged,
  });

  final int challengeId;
  final VoidCallback onChanged;

  @override
  ConsumerState<ChallengeCandidatesPanel> createState() => _ChallengeCandidatesPanelState();
}

class _ChallengeCandidatesPanelState extends ConsumerState<ChallengeCandidatesPanel> {
  List<ChallengeParticipant>? _candidates;
  bool _loading = true;
  int? _acceptingUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ref.read(challengesRepositoryProvider).listCandidates(widget.challengeId);
      if (mounted) {
        setState(() {
          _candidates = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptCandidate(ChallengeParticipant candidate) async {
    setState(() => _acceptingUserId = candidate.user.id);
    try {
      await ref.read(challengesRepositoryProvider).acceptCandidate(
            widget.challengeId,
            candidate.user.id,
          );
      widget.onChanged();
      await _load();
    } finally {
      if (mounted) setState(() => _acceptingUserId = null);
    }
  }

  Future<void> _openChat(ChallengeParticipant candidate) async {
    final conv = await ref.read(chatRepositoryProvider).start(
          candidate.user.id,
          candidate.user.name,
        );
    if (!mounted) return;
    openChatThread(context, conv);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    final candidates = _candidates ?? const [];
    if (candidates.isEmpty) {
      return Text(
        'Nenhum candidato ainda.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Candidatos (${candidates.length})', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...candidates.map((c) {
          final busy = _acceptingUserId == c.user.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(c.user.name, style: Theme.of(context).textTheme.titleSmall),
                  Text('NTRP ${c.user.ntrpRating.toStringAsFixed(1)}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : () => _openChat(c),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Conversar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LimeButton(
                          label: 'Aceitar',
                          loading: busy,
                          onPressed: busy ? null : () => _acceptCandidate(c),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
