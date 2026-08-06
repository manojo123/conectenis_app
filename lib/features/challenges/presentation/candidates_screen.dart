import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/presentation/widgets/challenge_mural_card.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

/// Prototype "Candidatos" screen: summary banner of the public challenge +
/// candidate cards with Recusar / Escolher adversário actions.
class CandidatesScreen extends ConsumerStatefulWidget {
  const CandidatesScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  ConsumerState<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends ConsumerState<CandidatesScreen> {
  Challenge? _challenge;
  List<ChallengeParticipant> _candidates = [];
  bool _loading = true;
  String? _error;
  int? _busyUserId;

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
      final repo = ref.read(challengesRepositoryProvider);
      final results = await Future.wait([
        repo.byId(widget.challengeId),
        repo.listCandidates(widget.challengeId),
      ]);
      if (!mounted) return;
      setState(() {
        _challenge = results[0] as Challenge;
        _candidates = results[1] as List<ChallengeParticipant>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _accept(ChallengeParticipant candidate) async {
    setState(() => _busyUserId = candidate.user.id);
    try {
      await ref.read(challengesRepositoryProvider).acceptCandidate(
            widget.challengeId,
            candidate.user.id,
          );
      bumpChallengesRefresh(ref);
      if (mounted) {
        showToast(context,
            'Partida agendada com ${candidate.user.name.split(' ').first}!');
      }
      await _load();
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busyUserId = null);
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
    final t = context.t;
    final c = _challenge;
    final df = DateFormat('EEE, dd/MM · HH:mm', 'pt_BR');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Candidatos'),
            if (c != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.tintAcc,
                    border:
                        Border.all(color: t.accent.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Symbols.sports_tennis_rounded,
                          size: 20, fill: 1, color: t.accentText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Seu desafio público',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: t.text,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' · ${df.format(c.scheduledStart)}\n${c.place?.name ?? 'Local em aberto'}'
                                    '${c.minNtrp != null ? ' · NTRP ${ntrpValueLabel(c.minNtrp!)} – ${c.maxNtrp != null ? ntrpValueLabel(c.maxNtrp!) : '—'}' : ''}',
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: t.muted,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _candidates.isEmpty
                          ? const EmptyState(
                              icon: Symbols.group_rounded,
                              title: 'Ainda não há candidatos',
                              subtitle:
                                  'Assim que alguém se candidatar, você escolhe aqui.',
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: EdgeInsets.fromLTRB(14, 0, 14,
                                    screenBottomInset(context) + 16),
                                itemCount: _candidates.length,
                                itemBuilder: (_, i) =>
                                    _candidateCard(t, _candidates[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _candidateCard(AppTokens t, ChallengeParticipant candidate) {
    final p = candidate.user;
    final busy = _busyUserId == p.id;
    final decided = candidate.status == 'accepted' || candidate.status == 'declined';
    final accepted = candidate.status == 'accepted';
    final sub = <String>[
      'NTRP ${ntrpValueLabel(p.ntrpRating)}',
      if (p.locationLabel.isNotEmpty) p.locationLabel,
      if (p.distanceKm != null)
        '${p.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                UserAvatar(
                  name: p.name,
                  avatarUrl: p.avatarUrl,
                  hasCustomAvatar: p.hasCustomAvatar,
                  userId: p.id,
                  radius: 24,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: t.muted),
                      ),
                    ],
                  ),
                ),
                if (decided)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: accepted ? t.tintSucc : t.tintErr,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      accepted ? 'Confirmado' : 'Recusado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: accepted ? t.success : t.error,
                      ),
                    ),
                  ),
              ],
            ),
            if (!decided) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CardActionButton(
                      label: 'Conversar',
                      kind: CardActionKind.outline,
                      onTap: busy ? null : () => _openChat(candidate),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    flex: 140,
                    child: CardActionButton(
                      label: 'Escolher adversário',
                      kind: CardActionKind.primary,
                      loading: busy,
                      onTap: busy ? null : () => _accept(candidate),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
