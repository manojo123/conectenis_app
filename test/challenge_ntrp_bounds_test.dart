import 'package:conectenis_app/shared/utils/challenge_ntrp_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allowed range is creator level ± 1 star clamped to 1.0–5.0', () {
    expect(ChallengeNtrpBounds.allowedMin(5.0), 4.0);
    expect(ChallengeNtrpBounds.allowedMax(5.0), 5.0);

    expect(ChallengeNtrpBounds.allowedMin(3.0), 2.0);
    expect(ChallengeNtrpBounds.allowedMax(3.0), 4.0);

    expect(ChallengeNtrpBounds.allowedMin(1.0), 1.0);
    expect(ChallengeNtrpBounds.allowedMax(1.0), 2.0);
  });

  test('isValidRange accepts values inside the allowed window', () {
    expect(
      ChallengeNtrpBounds.isValidRange(userNtrp: 3.0, minNtrp: 2.5, maxNtrp: 3.5),
      isTrue,
    );
    expect(
      ChallengeNtrpBounds.isValidRange(userNtrp: 5.0, minNtrp: 4.0, maxNtrp: 5.0),
      isTrue,
    );
    expect(
      ChallengeNtrpBounds.isValidRange(userNtrp: 5.0, minNtrp: 5.0, maxNtrp: 4.0),
      isFalse,
    );
    expect(
      ChallengeNtrpBounds.isValidRange(userNtrp: 3.0, minNtrp: 1.0, maxNtrp: 2.0),
      isFalse,
    );
  });
}
