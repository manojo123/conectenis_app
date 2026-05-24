import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';

final challengesRepositoryProvider = Provider<ChallengesRepository>((ref) {
  return ChallengesRepository(
    dio: ref.watch(dioProvider),
    mock: ref.watch(mockApiServiceProvider),
  );
});

class ChallengesRepository {
  ChallengesRepository({required Dio dio, required MockApiService mock})
      : _dio = dio,
        _mock = mock;

  final Dio _dio;
  final MockApiService _mock;

  Future<List<Challenge>> list(ChallengeListRole role) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.challenges(role: role);
      final response = await _dio.get<List<dynamic>>(
        '/challenges',
        queryParameters: {'role': role.value},
      );
      return (response.data ?? [])
          .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Challenge> byId(int id) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.challengeById(id);
      final response = await _dio.get<Map<String, dynamic>>('/challenges/$id');
      return Challenge.fromJson(response.data!);
    });
  }

  Future<Challenge> createDirect({
    required ChallengeFormat format,
    required List<int> participantIds,
    required int placeId,
    required DateTime scheduledStart,
    DateTime? scheduledEnd,
    String? message,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.createDirectChallenge(
          format: format,
          participantIds: participantIds,
          placeId: placeId,
          scheduledStart: scheduledStart,
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/challenges/direct',
        data: {
          'format': format.value,
          'participant_ids': participantIds,
          'place_id': placeId,
          'scheduled_start': scheduledStart.toIso8601String(),
          if (scheduledEnd != null) 'scheduled_end': scheduledEnd.toIso8601String(),
          'message': ?message,
        },
      );
      return Challenge.fromJson(response.data!);
    });
  }

  Future<Challenge> createPublic({
    required ChallengeFormat format,
    int? placeId,
    bool openLocation = false,
    required DateTime scheduledStart,
    DateTime? scheduledEnd,
    String? message,
    double? minNtrp,
    double? maxNtrp,
    Gender? genderPreference,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.createPublicChallenge(format: format, scheduledStart: scheduledStart);
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/challenges/public',
        data: {
          'format': format.value,
          'place_id': placeId,
          'open_location': openLocation,
          'scheduled_start': scheduledStart.toIso8601String(),
          if (scheduledEnd != null) 'scheduled_end': scheduledEnd.toIso8601String(),
          'message': ?message,
          'min_ntrp': ?minNtrp,
          'max_ntrp': ?maxNtrp,
          if (genderPreference != null) 'gender_preference': genderPreference.value,
        },
      );
      return Challenge.fromJson(response.data!);
    });
  }

  Future<Challenge> accept(int id) => _action(id, 'accept');
  Future<Challenge> decline(int id) => _action(id, 'decline');
  Future<Challenge> cancel(int id) => _action(id, 'cancel');
  Future<Challenge> apply(int id) => _action(id, 'apply');

  Future<void> submitEvaluation(
    int id, {
    required bool skipScore,
    int? myGamesWon,
    int? opponentGamesWon,
    int? winnerUserId,
    required int opponentPunctualityStars,
    String? opponentComment,
    int? placeQualityStars,
    String? placeComment,
  }) {
    return _guard(() async {
      if (Env.useMockApi) return;
      await _dio.post('/challenges/$id/evaluation', data: {
        'skip_score': skipScore,
        if (!skipScore) ...{
          'my_games_won': myGamesWon,
          'opponent_games_won': opponentGamesWon,
          'winner_user_id': winnerUserId,
        },
        'opponent_punctuality_stars': opponentPunctualityStars,
        'opponent_comment': ?opponentComment,
        'place_quality_stars': ?placeQualityStars,
        'place_comment': ?placeComment,
      });
    });
  }

  Future<Challenge> _action(int id, String action) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.challengeById(id);
      final response = await _dio.post<Map<String, dynamic>>('/challenges/$id/$action');
      return Challenge.fromJson(response.data!);
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
