import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
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
import 'package:conectenis_app/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      showToast(context,'Não foi possível identificar os adversários.');
      return;
    }

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

    int? myGames;
    int? opponentGames;
    if (!_skipScore) {
      myGames = int.tryParse(_myGames.text.trim());
      opponentGames = int.tryParse(_opponentGames.text.trim());
      if (myGames == null || opponentGames == null || myGames < 0 || opponentGames < 0) {
        showToast(
          context,
          'Informe o placar com números válidos ou marque "Não quero informar o placar".',
        );
        return;
      }
      if (_isTie) {
        if (_isDoubles && _tieMyTeamWins == null) {
          showToast(context,'Em caso de empate, selecione qual dupla venceu.');
          return;
        }
        if (!_isDoubles && _tieWinnerUserId == null) {
          showToast(context,'Em caso de empate, selecione quem venceu.');
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
          showToast(context,'Informe qual dupla venceu o desafio.');
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
          showToast(context,'Informe quem venceu o desafio.');
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
      showToast(
        context,
        'Resultado informado. Aguardando aprovação dos outros participantes.',
      );
      context.go('/challenges/${widget.challengeId}');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        showToast(context,e.message);
        context.go('/challenges/${widget.challengeId}');
        return;
      }
      showToast(context,e.message);
    } catch (e) {
      if (mounted) showToast(context,e.toString());
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
              const ScreenHeader(title: 'Registrar resultado', close: true),
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
    final currentUserId = ref.watch(authStateProvider).value?.id ?? 0;
    final opponentSideLabel = _opponentSideLabel(challenge, currentUserId);
    final opponents = challenge.opponentTeamUserIds(currentUserId);
    final opponentPlayer = opponents.isNotEmpty
        ? challenge.participantPlayer(opponents.first)
        : null;
    final df = DateFormat('EEE, dd/MM · HH:mm', 'pt_BR');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Registrar resultado', close: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(13),
                    radius: 16,
                    child: Row(
                      children: [
                        if (opponentPlayer != null)
                          UserAvatar(
                            name: opponentPlayer.name,
                            avatarUrl: opponentPlayer.avatarUrl,
                            hasCustomAvatar: opponentPlayer.hasCustomAvatar,
                            userId: opponentPlayer.id,
                            radius: 24,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'vs $opponentSideLabel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: t.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${df.format(challenge.scheduledStart)}${challenge.place != null ? ' · ${challenge.place!.name}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: t.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionLabel.caps('Informar placar'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      _skipScore = !_skipScore;
                      _tieWinnerUserId = null;
                      _tieMyTeamWins = null;
                    }),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _skipScore,
                          activeColor: t.accent,
                          checkColor: t.onAccent,
                          onChanged: (v) => setState(() {
                            _skipScore = v ?? false;
                            _tieWinnerUserId = null;
                            _tieMyTeamWins = null;
                          }),
                        ),
                        Expanded(
                          child: Text(
                            'Não quero informar o placar',
                            style: TextStyle(fontSize: 14, color: t.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_skipScore) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _myGames,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: t.text,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              helperText: _isDoubles
                                  ? 'Games da minha dupla'
                                  : 'Meus games',
                              helperStyle:
                                  TextStyle(fontSize: 11, color: t.muted),
                            ),
                            onChanged: (_) => setState(() {
                              _tieWinnerUserId = null;
                              _tieMyTeamWins = null;
                            }),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '×',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: t.disabled,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _opponentGames,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: t.text,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              helperText: 'Games de $opponentSideLabel',
                              helperStyle:
                                  TextStyle(fontSize: 11, color: t.muted),
                            ),
                            onChanged: (_) => setState(() {
                              _tieWinnerUserId = null;
                              _tieMyTeamWins = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                    if (_isTie) ...[
                      const SizedBox(height: 14),
                      const SectionLabel('Empate — quem venceu?'),
                      const SizedBox(height: 4),
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
                  const SizedBox(height: 22),
                  SectionLabel.caps(
                    _isDoubles ? 'Avaliar adversários' : 'Avaliar adversário',
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.tintInfo,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Symbols.info_rounded, size: 20, color: t.info),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'O placar vale pontos no ranking após confirmação do adversário. Resultados divergentes vão para revisão.',
                            style: TextStyle(
                                fontSize: 12.5, color: t.muted, height: 1.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LimeButton(
          label: 'Confirmar resultado',
          loading: _submitting,
          glow: true,
          onPressed: _submitting ? null : _submit,
        ),
      ),
    );
  }
}
