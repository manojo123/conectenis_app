import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/app_snackbar.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/opponent_rating_form.dart';
import 'package:conectenis_app/shared/widgets/place_rating_form.dart';
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
        AppSnackBar.showWarning(
          context,
          'Avalie pontualidade, fair play e comunicação de todos os adversários.',
        );
        return;
      }
    }

    if (challenge.place != null && !_placeRating.isComplete) {
      AppSnackBar.showWarning(
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
      AppSnackBar.showSuccess(context, 'Aprovação e avaliação registradas.');
      context.go('/challenges/${widget.challengeId}');
    } catch (e) {
      if (mounted) AppSnackBar.showDanger(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView(message: 'Carregando desafio...'));
    }
    if (_error != null || _challenge == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: _error ?? 'Desafio não encontrado', onRetry: _load),
      );
    }

    final challenge = _challenge!;
    final result = challenge.result;
    final currentUserId = ref.watch(authStateProvider).value?.id ?? 0;
    final opponents = challenge.opponentTeamUserIds(currentUserId);
    final isDoubles = challenge.format == ChallengeFormat.doubles;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar e avaliar')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          Text('RESULTADO PROPOSTO', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result?.submittedByName != null)
                    Text('Informado por ${result!.submittedByName}'),
                  const SizedBox(height: 8),
                  if (result?.skipScore == true)
                    const Text('Placar não informado')
                  else if (result?.scoreLabel != null)
                    Text(result!.scoreLabel!, style: Theme.of(context).textTheme.titleMedium)
                  else if (result?.myGamesWon != null)
                    Text('Placar: ${result!.myGamesWon} × ${result.opponentGamesWon}'),
                  if (result?.winnerName != null) Text('Vencedor: ${result!.winnerName}'),
                  if (result?.winnerTeamLabel != null)
                    Text('Dupla vencedora: ${result!.winnerTeamLabel}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isDoubles ? 'AVALIAR ADVERSÁRIOS' : 'AVALIAR ADVERSÁRIO',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 32),
          LimeButton(
            label: 'Aprovar resultado',
            loading: _submitting,
            glow: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
