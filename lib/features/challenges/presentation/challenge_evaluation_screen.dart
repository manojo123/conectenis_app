import 'package:conectenis_app/core/network/api_exception.dart';
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

class ChallengeEvaluationScreen extends ConsumerStatefulWidget {
  const ChallengeEvaluationScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  ConsumerState<ChallengeEvaluationScreen> createState() => _ChallengeEvaluationScreenState();
}

class _ChallengeEvaluationScreenState extends ConsumerState<ChallengeEvaluationScreen> {
  Challenge? _challenge;
  bool _loading = true;
  String? _error;
  bool _skipScore = false;
  final _myGames = TextEditingController();
  final _opponentGames = TextEditingController();
  final Map<int, OpponentRatingInput> _opponentRatings = {};
  final PlaceRatingInput _placeRating = PlaceRatingInput();
  int? _tieWinnerUserId;
  bool? _tieMyTeamWins;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _myGames.dispose();
    _opponentGames.dispose();
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
      if (challenge.hasProposedResult || !challenge.canSubmitResult) {
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

  bool get _isDoubles => _challenge?.format == ChallengeFormat.doubles;

  bool get _isTie {
    if (_skipScore) return false;
    final my = int.tryParse(_myGames.text.trim());
    final opp = int.tryParse(_opponentGames.text.trim());
    return my != null && opp != null && my == opp;
  }

  String _opponentSideLabel(Challenge challenge, int currentUserId) {
    if (_isDoubles) {
      final names = challenge
          .opponentTeamUserIds(currentUserId)
          .map((id) => challenge.participantName(id))
          .whereType<String>()
          .toList();
      return names.isEmpty ? 'Adversários' : names.join(' / ');
    }
    final id = challenge.opponentTeamUserIds(currentUserId).firstOrNull;
    return id == null ? 'Adversário' : (challenge.participantName(id) ?? 'Adversário');
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
    if (opponents.isEmpty) {
      AppSnackBar.showDanger(context, 'Não foi possível identificar os adversários.');
      return;
    }

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

    int? myGames;
    int? opponentGames;
    if (!_skipScore) {
      myGames = int.tryParse(_myGames.text.trim());
      opponentGames = int.tryParse(_opponentGames.text.trim());
      if (myGames == null || opponentGames == null || myGames < 0 || opponentGames < 0) {
        AppSnackBar.showWarning(
          context,
          'Informe o placar com números válidos ou marque "Não quero informar o placar".',
        );
        return;
      }
      if (_isTie) {
        if (_isDoubles && _tieMyTeamWins == null) {
          AppSnackBar.showWarning(context, 'Em caso de empate, selecione qual dupla venceu.');
          return;
        }
        if (!_isDoubles && _tieWinnerUserId == null) {
          AppSnackBar.showWarning(context, 'Em caso de empate, selecione quem venceu.');
          return;
        }
      }
    }

    int? winnerUserId;
    List<int>? winnerTeam;
    if (!_skipScore) {
      if (_isDoubles) {
        if (myGames! > opponentGames! || (_isTie && _tieMyTeamWins == true)) {
          winnerTeam = challenge.myTeamUserIds(currentUserId);
        } else if (myGames < opponentGames || (_isTie && _tieMyTeamWins == false)) {
          winnerTeam = challenge.opponentTeamUserIds(currentUserId);
        }
        if (winnerTeam == null || winnerTeam.length != 2) {
          AppSnackBar.showDanger(context, 'Informe qual dupla venceu o desafio.');
          return;
        }
      } else {
        final oppId = opponents.first;
        if (myGames! > opponentGames!) {
          winnerUserId = currentUserId;
        } else if (myGames < opponentGames) {
          winnerUserId = oppId;
        } else {
          winnerUserId = _tieWinnerUserId;
        }
        if (winnerUserId == null) {
          AppSnackBar.showDanger(context, 'Informe quem venceu o desafio.');
          return;
        }
      }
    }

    final opponentPayloads = _buildOpponentPayloads(opponents);
    final placeComment = _placeRating.commentController.text.trim();

    setState(() => _submitting = true);
    try {
      await ref.read(challengesRepositoryProvider).submitEvaluation(
            widget.challengeId,
            format: challenge.format,
            skipScore: _skipScore,
            myGamesWon: myGames,
            opponentGamesWon: opponentGames,
            winnerUserId: winnerUserId,
            winnerTeam: winnerTeam,
            opponentRatings: opponentPayloads,
            opponentPunctualityStars:
                !_isDoubles ? opponentPayloads.first.punctualityStars : null,
            opponentFairPlayStars: !_isDoubles ? opponentPayloads.first.fairPlayStars : null,
            opponentCommunicationStars:
                !_isDoubles ? opponentPayloads.first.communicationStars : null,
            opponentComment: !_isDoubles ? opponentPayloads.first.comment : null,
            courtQualityStars:
                challenge.place != null ? _placeRating.courtQualityStars : null,
            infrastructureStars:
                challenge.place != null ? _placeRating.infrastructureStars : null,
            placeComment: placeComment.isEmpty ? null : placeComment,
          );
      if (!mounted) return;
      bumpChallengesRefresh(ref);
      AppSnackBar.showSuccess(
        context,
        'Resultado informado. Aguardando aprovação dos outros participantes.',
      );
      context.go('/challenges/${widget.challengeId}');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        AppSnackBar.showWarning(context, e.message);
        context.go('/challenges/${widget.challengeId}');
        return;
      }
      AppSnackBar.showDanger(context, e.message);
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
    final currentUserId = ref.watch(authStateProvider).value?.id ?? 0;
    final opponentSideLabel = _opponentSideLabel(challenge, currentUserId);
    final opponents = challenge.opponentTeamUserIds(currentUserId);

    return Scaffold(
      appBar: AppBar(title: const Text('Avaliação do desafio')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          Text('INFORMAR PLACAR', style: Theme.of(context).textTheme.titleSmall),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _skipScore,
            onChanged: (v) => setState(() {
              _skipScore = v ?? false;
              _tieWinnerUserId = null;
              _tieMyTeamWins = null;
            }),
            title: const Text('Não quero informar o placar'),
          ),
          if (!_skipScore) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _myGames,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _isDoubles ? 'Games da minha dupla' : 'Meus games',
                    ),
                    onChanged: (_) => setState(() {
                      _tieWinnerUserId = null;
                      _tieMyTeamWins = null;
                    }),
                  ),
                ),
                const Padding(padding: EdgeInsets.all(8), child: Text('×')),
                Expanded(
                  child: TextField(
                    controller: _opponentGames,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Games de $opponentSideLabel'),
                    onChanged: (_) => setState(() {
                      _tieWinnerUserId = null;
                      _tieMyTeamWins = null;
                    }),
                  ),
                ),
              ],
            ),
            if (_isTie) ...[
              const SizedBox(height: 12),
              Text('Empate — quem venceu?', style: Theme.of(context).textTheme.titleSmall),
              if (_isDoubles)
                RadioGroup<bool>(
                  groupValue: _tieMyTeamWins,
                  onChanged: (v) => setState(() => _tieMyTeamWins = v),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Minha dupla venceu'),
                        value: true,
                      ),
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Dupla adversária venceu'),
                        value: false,
                      ),
                    ],
                  ),
                )
              else ...[
                RadioGroup<int>(
                  groupValue: _tieWinnerUserId,
                  onChanged: (v) => setState(() => _tieWinnerUserId = v),
                  child: Column(
                    children: [
                      RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Eu venci'),
                        value: currentUserId,
                      ),
                      RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('$opponentSideLabel venceu'),
                        value: opponents.first,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
          const SizedBox(height: 24),
          Text(
            _isDoubles ? 'AVALIAR ADVERSÁRIOS' : 'AVALIAR ADVERSÁRIO',
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
            label: 'Enviar avaliação',
            loading: _submitting,
            glow: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
