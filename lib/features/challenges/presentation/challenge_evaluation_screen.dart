import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/challenge_result.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/utils/match_score.dart';
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

/// Text controllers for one set's games, plus its own tiebreak (shown once
/// that set reaches its format's trigger score - 6-6, or 8-8 for the
/// single `pro_set_9` set).
class _SetInputControllers {
  final myGames = TextEditingController();
  final opponentGames = TextEditingController();
  final myTiebreak = TextEditingController();
  final opponentTiebreak = TextEditingController();

  void dispose() {
    myGames.dispose();
    opponentGames.dispose();
    myTiebreak.dispose();
    opponentTiebreak.dispose();
  }
}

int? _parseInt(TextEditingController c) => int.tryParse(c.text.trim());

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

  // Up to 3 set rows; how many are shown/required depends on scoringFormat.
  final List<_SetInputControllers> _setInputs =
      List.generate(3, (_) => _SetInputControllers());

  // Match-deciding tiebreak: pro_set_9's 8-8 breaker, or
  // two_sets_super_tiebreak's decider when the two sets split 1-1.
  final _superTbMy = TextEditingController();
  final _superTbOpp = TextEditingController();

  // Explicit "went to a tiebreak" toggles, rather than inferring it from
  // typed game numbers - a real scoreboard reads "7-6", but the backend
  // wants that set's games recorded as 6-6 (see docs/BACKEND_PROMPT_...).
  // Toggling on locks the games fields at the trigger score so the
  // submitted shape can't drift from what the user sees.
  final List<bool> _setTiebreakToggled = List.filled(3, false);
  bool _proSetSuperTiebreak = false;

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
    for (final s in _setInputs) {
      s.dispose();
    }
    _superTbMy.dispose();
    _superTbOpp.dispose();
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
  ScoringFormat get _scoringFormat =>
      _challenge?.scoringFormat ?? ScoringFormat.bestOfThreeSets;

  /// Parses set [index] from its controllers, or null if incomplete.
  SetScore? _parsedSet(int index) {
    final myG = _parseInt(_setInputs[index].myGames);
    final oppG = _parseInt(_setInputs[index].opponentGames);
    if (myG == null || oppG == null) return null;
    final myTb = _parseInt(_setInputs[index].myTiebreak);
    final oppTb = _parseInt(_setInputs[index].opponentTiebreak);
    final tiebreak = myTb != null && oppTb != null
        ? TiebreakScore(myPoints: myTb, opponentPoints: oppTb)
        : null;
    return SetScore(myGames: myG, opponentGames: oppG, tiebreak: tiebreak);
  }

  /// Parses up to [count] set rows in order, stopping at the first
  /// incomplete one (an incomplete row 2 shouldn't be read as "set 2").
  List<SetScore> _parsedSets(int count) {
    final list = <SetScore>[];
    for (var i = 0; i < count; i++) {
      final s = _parsedSet(i);
      if (s == null) break;
      list.add(s);
    }
    return list;
  }

  TiebreakScore? get _superTiebreak {
    final myTb = _parseInt(_superTbMy);
    final oppTb = _parseInt(_superTbOpp);
    if (myTb == null || oppTb == null) return null;
    return TiebreakScore(myPoints: myTb, opponentPoints: oppTb);
  }

  /// How many set rows to show right now for [_scoringFormat].
  int get _visibleSetRows {
    switch (_scoringFormat) {
      case ScoringFormat.proSet9:
        return 1;
      case ScoringFormat.twoSetsSuperTiebreak:
        return 2;
      case ScoringFormat.bestOfThreeSets:
        final firstTwo = _parsedSets(2);
        return needsThirdSet(_scoringFormat, firstTwo) ? 3 : 2;
    }
  }

  /// True when set [index] should show its own tiebreak points row
  /// (not applicable to pro_set_9's single set, which uses the shared
  /// super-tiebreak row instead - see [_needsSuperTiebreakRow]).
  bool _setNeedsOwnTiebreak(int index) =>
      _scoringFormat != ScoringFormat.proSet9 && _setTiebreakToggled[index];

  void _toggleSetTiebreak(int index, bool value) {
    setState(() {
      _setTiebreakToggled[index] = value;
      if (value) {
        final trigger = setTiebreakTrigger(_scoringFormat).toString();
        _setInputs[index].myGames.text = trigger;
        _setInputs[index].opponentGames.text = trigger;
      }
    });
  }

  /// True when the shared super-tiebreak row should show.
  bool get _needsSuperTiebreakRow {
    if (_scoringFormat == ScoringFormat.proSet9) return _proSetSuperTiebreak;
    if (_scoringFormat == ScoringFormat.twoSetsSuperTiebreak) {
      return needsSuperTiebreak(_scoringFormat, _parsedSets(2));
    }
    return false;
  }

  void _toggleProSetSuperTiebreak(bool value) {
    setState(() {
      _proSetSuperTiebreak = value;
      if (value) {
        _setInputs[0].myGames.text = '8';
        _setInputs[0].opponentGames.text = '8';
      }
    });
  }

  /// Sets ready for submission. pro_set_9's single set never carries its own
  /// `tiebreak` (the toggle for it is never shown for that format, so those
  /// controllers stay empty) - the 8-8 decider only ever reaches the
  /// backend via the top-level `super_tiebreak`.
  List<SetScore> get _submitSets => _parsedSets(_visibleSetRows);

  /// Top-level `super_tiebreak` for submission - the 8-8 decider for
  /// pro_set_9, or two_sets_super_tiebreak's decider once its sets split
  /// 1-1. Always null for best_of_three_sets (a 3rd set decides instead).
  TiebreakScore? get _submitSuperTiebreak {
    if (_scoringFormat == ScoringFormat.bestOfThreeSets) return null;
    return _superTiebreak;
  }

  MatchSide? get _winner {
    if (_skipScore) return null;
    return matchWinner(
      format: _scoringFormat,
      sets: _submitSets,
      superTiebreak: _submitSuperTiebreak,
    );
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
      showToast(context, 'Não foi possível identificar os adversários.');
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

    MatchSide? winner;
    if (!_skipScore) {
      winner = _winner;
      if (winner == null) {
        showToast(
          context,
          'Informe o placar completo (incluindo o tiebreak, se necessário) ou marque "Não quero informar o placar".',
        );
        return;
      }
    }

    int? winnerUserId;
    List<int>? winnerTeam;
    if (winner != null) {
      if (_isDoubles) {
        winnerTeam = winner == MatchSide.me
            ? challenge.myTeamUserIds(currentUserId)
            : challenge.opponentTeamUserIds(currentUserId);
      } else {
        winnerUserId = winner == MatchSide.me ? currentUserId : opponents.first;
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
            sets: _skipScore ? null : _submitSets,
            superTiebreak: _skipScore ? null : _submitSuperTiebreak,
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
        showToast(context, e.message);
        context.go('/challenges/${widget.challengeId}');
        return;
      }
      showToast(context, e.message);
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
                  SectionLabel.caps('Informar placar · ${_scoringFormat.label}'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _skipScore = !_skipScore),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _skipScore,
                          activeColor: t.accent,
                          checkColor: t.onAccent,
                          onChanged: (v) => setState(() => _skipScore = v ?? false),
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
                  if (!_skipScore) ..._scoreEntrySection(t, opponentSideLabel),
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

  List<Widget> _scoreEntrySection(AppTokens t, String opponentSideLabel) {
    final rows = _visibleSetRows;
    final isProSet = _scoringFormat == ScoringFormat.proSet9;
    final widgets = <Widget>[];
    for (var i = 0; i < rows; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 14));
      final locked = isProSet ? _proSetSuperTiebreak : _setTiebreakToggled[i];
      widgets.add(_setRow(
        t,
        i,
        opponentSideLabel,
        setLabel: rows > 1 ? 'Set ${i + 1}' : null,
        locked: locked,
      ));
      widgets.add(const SizedBox(height: 6));
      if (isProSet) {
        widgets.add(_toggleRow(
          t,
          label: 'Foi para o super tiebreak (8-8)',
          value: _proSetSuperTiebreak,
          onChanged: _toggleProSetSuperTiebreak,
        ));
        if (_proSetSuperTiebreak) {
          widgets.add(const SizedBox(height: 8));
          widgets.add(_tiebreakRow(
            t,
            myController: _superTbMy,
            opponentController: _superTbOpp,
            label: 'Super tiebreak (decide a partida)',
          ));
        }
      } else {
        widgets.add(_toggleRow(
          t,
          label: 'Foi a tiebreak (6-6)',
          value: _setTiebreakToggled[i],
          onChanged: (v) => _toggleSetTiebreak(i, v),
        ));
        if (_setNeedsOwnTiebreak(i)) {
          widgets.add(const SizedBox(height: 8));
          widgets.add(_tiebreakRow(
            t,
            myController: _setInputs[i].myTiebreak,
            opponentController: _setInputs[i].opponentTiebreak,
            label: 'Tiebreak do set ${i + 1}',
          ));
        }
      }
    }
    if (_scoringFormat == ScoringFormat.twoSetsSuperTiebreak && _needsSuperTiebreakRow) {
      widgets.add(const SizedBox(height: 14));
      widgets.add(Text(
        'Sets divididos 1-1, informe o super tiebreak que decidiu a partida:',
        style: TextStyle(fontSize: 12, color: t.muted),
      ));
      widgets.add(const SizedBox(height: 8));
      widgets.add(_tiebreakRow(
        t,
        myController: _superTbMy,
        opponentController: _superTbOpp,
        label: 'Super tiebreak (decide a partida)',
      ));
    }
    return widgets;
  }

  Widget _toggleRow(
    AppTokens t, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: t.accent,
            checkColor: t.onAccent,
            visualDensity: VisualDensity.compact,
            onChanged: (v) => onChanged(v ?? false),
          ),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.5, color: t.text)),
          ),
        ],
      ),
    );
  }

  Widget _setRow(
    AppTokens t,
    int index,
    String opponentSideLabel, {
    String? setLabel,
    bool locked = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (setLabel != null) ...[
          Text(
            setLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.muted),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _setInputs[index].myGames,
                enabled: !locked,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: t.text),
                decoration: InputDecoration(
                  hintText: '0',
                  helperText: _isDoubles ? 'Games da minha dupla' : 'Meus games',
                  helperStyle: TextStyle(fontSize: 11, color: t.muted),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '×',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: t.disabled),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _setInputs[index].opponentGames,
                enabled: !locked,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: t.text),
                decoration: InputDecoration(
                  hintText: '0',
                  helperText: 'Games de $opponentSideLabel',
                  helperStyle: TextStyle(fontSize: 11, color: t.muted),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tiebreakRow(
    AppTokens t, {
    required TextEditingController myController,
    required TextEditingController opponentController,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.warning)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: myController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: t.text),
                decoration: const InputDecoration(hintText: '0'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('×', style: TextStyle(fontSize: 16, color: t.disabled)),
            ),
            Expanded(
              child: TextField(
                controller: opponentController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: t.text),
                decoration: const InputDecoration(hintText: '0'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
