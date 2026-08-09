import 'package:flutter_test/flutter_test.dart';
import 'package:conectenis_app/shared/models/challenge_result.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/utils/match_score.dart';

void main() {
  group('pro_set_9', () {
    const format = ScoringFormat.proSet9;

    test('straight games win, no tiebreak needed', () {
      final sets = [const SetScore(myGames: 9, opponentGames: 7)];
      expect(matchWinner(format: format, sets: sets), MatchSide.me);
    });

    test('opponent wins straight', () {
      final sets = [const SetScore(myGames: 6, opponentGames: 9)];
      expect(matchWinner(format: format, sets: sets), MatchSide.opponent);
    });

    test('8-8 decided by the top-level super_tiebreak', () {
      final sets = [const SetScore(myGames: 8, opponentGames: 8)];
      const superTb = TiebreakScore(myPoints: 6, opponentPoints: 10);
      expect(
        matchWinner(format: format, sets: sets, superTiebreak: superTb),
        MatchSide.opponent,
      );
    });

    test('8-8 with no super_tiebreak recorded is incomplete', () {
      final sets = [const SetScore(myGames: 8, opponentGames: 8)];
      expect(matchWinner(format: format, sets: sets), isNull);
    });

    test('a tiebreak on the set itself is ignored - only super_tiebreak counts', () {
      final sets = [
        const SetScore(
          myGames: 8,
          opponentGames: 8,
          tiebreak: TiebreakScore(myPoints: 10, opponentPoints: 8),
        ),
      ];
      expect(matchWinner(format: format, sets: sets), isNull);
      expect(
        matchWinner(
          format: format,
          sets: sets,
          superTiebreak: const TiebreakScore(myPoints: 4, opponentPoints: 10),
        ),
        MatchSide.opponent,
      );
    });

    test('tied below the trigger score is incomplete', () {
      final sets = [const SetScore(myGames: 6, opponentGames: 6)];
      expect(matchWinner(format: format, sets: sets), isNull);
    });

    test('wrong set count is incomplete', () {
      expect(matchWinner(format: format, sets: const []), isNull);
      final sets = [
        const SetScore(myGames: 9, opponentGames: 7),
        const SetScore(myGames: 9, opponentGames: 7),
      ];
      expect(matchWinner(format: format, sets: sets), isNull);
    });
  });

  group('two_sets_super_tiebreak', () {
    const format = ScoringFormat.twoSetsSuperTiebreak;

    test('straight 2-0 needs no super tiebreak', () {
      final sets = [
        const SetScore(myGames: 6, opponentGames: 4),
        const SetScore(myGames: 6, opponentGames: 3),
      ];
      expect(matchWinner(format: format, sets: sets), MatchSide.me);
      expect(needsSuperTiebreak(format, sets), isFalse);
    });

    test('set at 6-6 uses its own tiebreak', () {
      final sets = [
        const SetScore(myGames: 6, opponentGames: 4),
        const SetScore(
          myGames: 6,
          opponentGames: 6,
          tiebreak: TiebreakScore(myPoints: 7, opponentPoints: 3),
        ),
      ];
      expect(matchWinner(format: format, sets: sets), MatchSide.me);
    });

    test('split 1-1 requires the super tiebreak to decide', () {
      final sets = [
        const SetScore(myGames: 6, opponentGames: 4),
        const SetScore(myGames: 3, opponentGames: 6),
      ];
      expect(needsSuperTiebreak(format, sets), isTrue);
      expect(matchWinner(format: format, sets: sets), isNull);
      expect(
        matchWinner(
          format: format,
          sets: sets,
          superTiebreak: const TiebreakScore(myPoints: 10, opponentPoints: 4),
        ),
        MatchSide.me,
      );
    });

    test('wrong set count is incomplete', () {
      final sets = [const SetScore(myGames: 6, opponentGames: 4)];
      expect(matchWinner(format: format, sets: sets), isNull);
    });
  });

  group('best_of_three_sets', () {
    const format = ScoringFormat.bestOfThreeSets;

    test('straight 2-0 needs no 3rd set', () {
      final sets = [
        const SetScore(myGames: 6, opponentGames: 4),
        const SetScore(myGames: 7, opponentGames: 5),
      ];
      expect(needsThirdSet(format, sets), isFalse);
      expect(matchWinner(format: format, sets: sets), MatchSide.me);
    });

    test('split 1-1 requires a 3rd set', () {
      final sets = [
        const SetScore(myGames: 6, opponentGames: 4),
        const SetScore(myGames: 3, opponentGames: 6),
      ];
      expect(needsThirdSet(format, sets), isTrue);
      expect(matchWinner(format: format, sets: sets), isNull);
    });

    test('3rd set decides after a 1-1 split', () {
      final sets = [
        const SetScore(myGames: 6, opponentGames: 4),
        const SetScore(myGames: 3, opponentGames: 6),
        const SetScore(myGames: 6, opponentGames: 2),
      ];
      expect(matchWinner(format: format, sets: sets), MatchSide.me);
    });

    test('super_tiebreak is never consulted for this format', () {
      final sets = [
        const SetScore(myGames: 6, opponentGames: 4),
        const SetScore(myGames: 3, opponentGames: 6),
        const SetScore(myGames: 4, opponentGames: 6),
      ];
      expect(
        matchWinner(
          format: format,
          sets: sets,
          superTiebreak: const TiebreakScore(myPoints: 10, opponentPoints: 0),
        ),
        MatchSide.opponent,
      );
    });

    test('each set at 6-6 uses its own tiebreak', () {
      final sets = [
        const SetScore(
          myGames: 6,
          opponentGames: 6,
          tiebreak: TiebreakScore(myPoints: 7, opponentPoints: 2),
        ),
        const SetScore(
          myGames: 6,
          opponentGames: 6,
          tiebreak: TiebreakScore(myPoints: 4, opponentPoints: 7),
        ),
      ];
      expect(needsThirdSet(format, sets), isTrue);
    });
  });
}
