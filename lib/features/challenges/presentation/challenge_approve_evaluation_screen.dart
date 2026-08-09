import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/challenge_result.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/app_card.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/bottom_action_bar.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/opponent_rating_form.dart';
import 'package:conectenis_app/shared/widgets/place_rating_form.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChallengeApproveEvaluationScreen extends ConsumerStatefulWidget {
  const ChallengeApproveEvaluationScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  ConsumerState<ChallengeApproveEvaluationScreen> createState() =>
      _ChallengeApproveEvaluationScreenState();
}

class _ChallengeApproveEvaluationScreenState
    extends ConsumerState<ChallengeApproveEvaluationScreen> {
  Challenge? _challenge;
  bool _loading = true;
  String? _error;
  final Map<int, OpponentRatingInput> _opponentRatings = {};
  final PlaceRatingInput _placeRating = PlaceRatingInput();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _placeRating.dispose();
    for (final state in _opponentRatings.values) {
      state.dispose();
    }
    super.dispose();
  }

  void _initOpponentRatings(Challenge challenge, int currentUserId) {
    if (_opponentRatings.isNotEmpty) return;
    for (final id in challenge.opponentTeamUserIds(currentUserId)) {
      _opponentRatings[id] = OpponentRatingInput();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final challenge = await ref.read(challengesRepositoryProvider).byId(widget.challengeId);
      if (!mounted) return;
      if (!challenge.canApproveResult) {
        context.go('/challenges/${widget.challengeId}');
        return;
      }
      final userId = ref.read(authStateProvider).value?.id;
      if (userId != null) _initOpponentRatings(challenge, userId);
      setState(() {
        _challenge = challenge;
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

  /// e.g. "Set 1: 6-4 · Set 2: 6-7 (tiebreak 5-7) · Super tiebreak: 10-8" -
  /// display-only detail alongside the backend's `score_label`; this screen
  /// never re-derives the winner from it.
  String _setsBreakdown(ChallengeResult result) {
    final parts = <String>[
      for (final (i, set) in result.sets.indexed)
        'Set ${i + 1}: ${set.myGames}-${set.opponentGames}'
            '${set.tiebreak != null ? ' (tiebreak ${set.tiebreak!.myPoints}-${set.tiebreak!.opponentPoints})' : ''}',
      if (result.superTiebreak != null)
        'Super tiebreak: ${result.superTiebreak!.myPoints}-${result.superTiebreak!.opponentPoints}',
    ];
    return parts.join(' · ');
  }

  List<OpponentRatingPayload> _buildOpponentPayloads(List<int> opponents) {
    return opponents
        .map(
          (id) => OpponentRatingPayload(
            userId: id,
            punctualityStars: _opponentRatings[id]!.punctualityStars,
            fairPlayStars: _opponentRatings[id]!.fairPlayStars,
            communicationStars: _opponentRatings[id]!.communicationStars,
            comment: _opponentRatings[id]!.commentController.text.trim().isEmpty
                ? null
                : _opponentRatings[id]!.commentController.text.trim(),
          ),
        )
        .toList();
  }

  Future<void> _submit() async {
    final challenge = _challenge;
    final currentUserId = ref.read(authStateProvider).value?.id;
    if (challenge == null || currentUserId == null) return;

    final opponents = challenge.opponentTeamUserIds(currentUserId);
    for (final id in opponents) {
      final rating = _opponentRatings[id];
      if (rating == null || !rating.isComplete) {
        showToast(
          context,
          'Avalie pontualidade, fair play e comunicação de todos os adversários.',
        );
        return;
      }
    }

    if (challenge.place != null && !_placeRating.isComplete) {
      showToast(
        context,
        'Avalie a qualidade da quadra e a infraestrutura do local.',
      );
      return;
    }

    final placeComment = _placeRating.commentController.text.trim();
    setState(() => _submitting = true);
    try {
      await ref.read(challengesRepositoryProvider).approveResult(
            widget.challengeId,
            opponentRatings: _buildOpponentPayloads(opponents),
            courtQualityStars:
                challenge.place != null ? _placeRating.courtQualityStars : null,
            infrastructureStars:
                challenge.place != null ? _placeRating.infrastructureStars : null,
            placeComment: placeComment.isEmpty ? null : placeComment,
          );
      if (!mounted) return;
      bumpChallengesRefresh(ref);
      showToast(context, 'Aprovação e avaliação registradas.');
      context.go('/challenges/${widget.challengeId}');
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (_loading) {
      return const Scaffold(body: LoadingView(message: 'Carregando desafio...'));
    }
    if (_error != null || _challenge == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Confirmar e avaliar', close: true),
              Expanded(
                child: ErrorView(
                  message: _error ?? 'Desafio não encontrado',
                  onRetry: _load,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final challenge = _challenge!;
    final result = challenge.result;
    final currentUserId = ref.watch(authStateProvider).value?.id ?? 0;
    final opponents = challenge.opponentTeamUserIds(currentUserId);
    final isDoubles = challenge.format == ChallengeFormat.doubles;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Confirmar e avaliar', close: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  const SectionLabel.caps('Resultado proposto'),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (result?.submittedByName != null)
                          Text(
                            'Informado por ${result!.submittedByName}',
                            style: TextStyle(fontSize: 12.5, color: t.muted),
                          ),
                        const SizedBox(height: 8),
                        if (result?.skipScore == true)
                          Text(
                            'Placar não informado',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: t.text,
                            ),
                          )
                        else if (result?.scoreLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 9),
                            decoration: BoxDecoration(
                              color: t.surface2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              result!.scoreLabel!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: t.text,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        if (result != null && result.sets.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _setsBreakdown(result),
                            style: TextStyle(fontSize: 12.5, color: t.muted, height: 1.5),
                          ),
                        ],
                        if (result?.winnerName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Vencedor: ${result!.winnerName}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.success,
                            ),
                          ),
                        ],
                        if (result?.winnerTeamLabel != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Dupla vencedora: ${result!.winnerTeamLabel}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SectionLabel.caps(
                    isDoubles ? 'Avaliar adversários' : 'Avaliar adversário',
                  ),
                  const SizedBox(height: 10),
                  ...opponents.map(
                    (id) => OpponentRatingForm(
                      player: challenge.participantPlayer(id),
                      rating: _opponentRatings[id] ??= OpponentRatingInput(),
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  if (challenge.place != null) ...[
                    const SizedBox(height: 12),
                    PlaceRatingForm(
                      placeName: challenge.place!.name,
                      rating: _placeRating,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LimeButton(
          label: 'Aprovar resultado',
          loading: _submitting,
          glow: true,
          onPressed: _submitting ? null : _submit,
        ),
      ),
    );
  }
}
