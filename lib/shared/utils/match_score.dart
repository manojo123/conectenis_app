import 'package:conectenis_app/shared/models/challenge_result.dart';
import 'package:conectenis_app/shared/models/enums.dart';

/// Which side won a set or the match. Kept generic (not player-specific)
/// since the evaluation screen always frames scores from "my" perspective.
enum MatchSide { me, opponent }

/// Games score at which a set's own `tiebreak` field applies - 6-6 for a
/// normal set. `pro_set_9` has no per-set tiebreak trigger: its 8-8 decider
/// lives only in the top-level `super_tiebreak` (see [matchWinner]).
int setTiebreakTrigger(ScoringFormat format) =>
    format == ScoringFormat.proSet9 ? 8 : 6;

MatchSide? _tiebreakWinner(TiebreakScore? tb) {
  if (tb == null || tb.myPoints == tb.opponentPoints) return null;
  return tb.myPoints > tb.opponentPoints ? MatchSide.me : MatchSide.opponent;
}

/// Winner of a single set, or null if it's incomplete/invalid (tied below
/// the tiebreak trigger, or tied at the trigger with no tiebreak recorded).
MatchSide? setWinner(SetScore set, ScoringFormat format) {
  if (set.myGames == set.opponentGames) {
    if (set.myGames >= setTiebreakTrigger(format)) {
      return _tiebreakWinner(set.tiebreak);
    }
    return null;
  }
  return set.myGames > set.opponentGames ? MatchSide.me : MatchSide.opponent;
}

/// True once `best_of_three_sets`' first two sets have split 1-1, so a 3rd
/// set entry should be shown/required.
bool needsThirdSet(ScoringFormat format, List<SetScore> sets) {
  if (format != ScoringFormat.bestOfThreeSets || sets.length < 2) return false;
  final w1 = setWinner(sets[0], format);
  final w2 = setWinner(sets[1], format);
  return w1 != null && w2 != null && w1 != w2;
}

/// True once `two_sets_super_tiebreak`'s two sets have split 1-1, so the
/// match-deciding super tiebreak entry should be shown/required (instead of
/// a 3rd set).
bool needsSuperTiebreak(ScoringFormat format, List<SetScore> sets) {
  if (format != ScoringFormat.twoSetsSuperTiebreak || sets.length < 2) return false;
  final w1 = setWinner(sets[0], format);
  final w2 = setWinner(sets[1], format);
  return w1 != null && w2 != null && w1 != w2;
}

/// Overall match winner for [format] given the sets (and match-deciding
/// tiebreak) submitted so far, or null if that data doesn't yet (or
/// doesn't validly) decide it.
///
/// `pro_set_9` note (confirmed against the backend contract): the single
/// set's own `tiebreak` is always null for this format - its 8-8 decider
/// lives only in the top-level [superTiebreak].
MatchSide? matchWinner({
  required ScoringFormat format,
  required List<SetScore> sets,
  TiebreakScore? superTiebreak,
}) {
  switch (format) {
    case ScoringFormat.proSet9:
      if (sets.length != 1) return null;
      final set = sets.first;
      if (set.myGames == set.opponentGames && set.myGames == 8) {
        return _tiebreakWinner(superTiebreak);
      }
      return setWinner(set, format);

    case ScoringFormat.twoSetsSuperTiebreak:
      if (sets.length != 2) return null;
      final w1 = setWinner(sets[0], format);
      final w2 = setWinner(sets[1], format);
      if (w1 == null || w2 == null) return null;
      if (w1 == w2) return w1;
      return _tiebreakWinner(superTiebreak);

    case ScoringFormat.bestOfThreeSets:
      if (sets.length < 2) return null;
      final w1 = setWinner(sets[0], format);
      final w2 = setWinner(sets[1], format);
      if (w1 == null || w2 == null) return null;
      if (w1 == w2) return w1;
      if (sets.length < 3) return null;
      return setWinner(sets[2], format);
  }
}
