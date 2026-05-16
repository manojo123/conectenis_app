import 'package:flutter_test/flutter_test.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

void main() {
  test('UserProfile fromJson roundtrip', () {
    const profile = UserProfile(
      id: 1,
      name: 'Test',
      email: 'test@example.com',
      age: 30,
      skillLevel: SkillLevel.intermediate,
      playStyle: PlayStyle.singles,
      profileComplete: true,
    );

    final json = profile.toJson();
    final restored = UserProfile.fromJson(json);

    expect(restored.id, 1);
    expect(restored.name, 'Test');
    expect(restored.skillLevel, SkillLevel.intermediate);
    expect(restored.profileComplete, true);
  });

  test('SkillLevel fromValue defaults to intermediate', () {
    expect(SkillLevel.fromValue(null), SkillLevel.intermediate);
    expect(SkillLevel.fromValue('advanced'), SkillLevel.advanced);
  });
}
