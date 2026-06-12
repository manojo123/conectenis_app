import 'package:conectenis_app/features/challenges/utils/challenge_wall_utils.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

Challenge _challenge(int id, ChallengeStatus status, DateTime start) {
  return Challenge(
    id: id,
    type: ChallengeType.direct,
    format: ChallengeFormat.singles,
    status: status,
    scheduledStart: start,
    creator: Player(id: 1, name: 'A', latitude: 0, longitude: 0),
  );
}

void main() {
  test('sortChallengesByPriority puts pending acceptance before accepted', () {
    final items = [
      _challenge(1, ChallengeStatus.accepted, DateTime(2026, 6, 20)),
      _challenge(2, ChallengeStatus.pendingAcceptance, DateTime(2026, 6, 25)),
    ];
    final sorted = sortChallengesByPriority(items);
    expect(sorted.first.id, 2);
  });

  test('partitionChallenges splits history from actionable', () {
    final items = [
      _challenge(1, ChallengeStatus.pendingScore, DateTime(2026, 6, 10)),
      _challenge(2, ChallengeStatus.completed, DateTime(2026, 5, 1)),
      _challenge(3, ChallengeStatus.cancelled, DateTime(2026, 4, 1)),
    ];
    final parts = partitionChallenges(items);
    expect(parts.actionable.length, 1);
    expect(parts.history.length, 2);
  });
}
