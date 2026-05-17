import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
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
      roles: ['user'],
    );

    final json = profile.toJson();
    final restored = UserProfile.fromJson(json);

    expect(restored.id, 1);
    expect(restored.name, 'Test');
    expect(restored.skillLevel, SkillLevel.intermediate);
    expect(restored.profileComplete, true);
    expect(restored.roles, ['user']);
  });

  test('UserProfile fromLaravelUser parses roles and email_verified_at', () {
    final profile = UserProfile.fromLaravelUser({
      'id': 2,
      'name': 'Maria',
      'email': 'maria@example.com',
      'email_verified_at': '2026-05-01T12:00:00.000000Z',
      'roles': ['user', 'admin'],
    });

    expect(profile.id, 2);
    expect(profile.name, 'Maria');
    expect(profile.roles, ['user', 'admin']);
    expect(profile.emailVerifiedAt, isNotNull);
  });

  test('ApiException parses Laravel 422 validation errors', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/register'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        statusCode: 422,
        data: {
          'message': 'The given data was invalid.',
          'errors': {
            'email': ['The email has already been taken.'],
          },
        },
      ),
    );

    final apiError = ApiException.fromDio(error);
    expect(apiError.message, 'The email has already been taken.');
    expect(apiError.statusCode, 422);
    expect(apiError.fieldErrors?['email']?.first, contains('taken'));
  });

  test('SkillLevel fromValue defaults to intermediate', () {
    expect(SkillLevel.fromValue(null), SkillLevel.intermediate);
    expect(SkillLevel.fromValue('advanced'), SkillLevel.advanced);
  });
}
