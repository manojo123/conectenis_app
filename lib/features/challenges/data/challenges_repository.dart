import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/features/challenges/models/public_challenge_filters.dart';
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

  Future<List<Challenge>> list(
    ChallengeListRole role, {
    PublicChallengeFilters? filters,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.challenges(role: role, filters: filters);
      }
      final queryParameters = <String, dynamic>{'role': role.value};
      if (role == ChallengeListRole.publicNearby && filters != null) {
        queryParameters.addAll(filters.toQueryParameters());
      }
      final response = await _dio.get<List<dynamic>>(
        '/challenges',
        queryParameters: queryParameters,
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
    int? placeId,
    String? googlePlaceId,
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
          googlePlaceId: googlePlaceId,
          scheduledStart: scheduledStart,
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/challenges/direct',
        data: {
          'format': format.value,
          'participant_ids': participantIds,
          'place_id': ?placeId,
          'google_place_id': ?googlePlaceId,
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
    String? googlePlaceId,
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
        return _mock.createPublicChallenge(
          format: format,
          scheduledStart: scheduledStart,
          placeId: placeId,
          googlePlaceId: googlePlaceId,
          openLocation: openLocation,
          minNtrp: minNtrp,
          maxNtrp: maxNtrp,
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/challenges/public',
        data: {
          'format': format.value,
          'place_id': ?placeId,
          'google_place_id': ?googlePlaceId,
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

  /// Submits proposed result. Returns updated challenge, or throws [ApiException]
  /// with status 409 when result was already submitted (caller should reload).
  Future<Challenge> submitEvaluation(
    int id, {
    required ChallengeFormat format,
    required bool skipScore,
    int? myGamesWon,
    int? opponentGamesWon,
    int? winnerUserId,
    List<int>? winnerTeam,
    List<OpponentRatingPayload>? opponentRatings,
    int? opponentPunctualityStars,
    String? opponentComment,
    int? placeQualityStars,
    String? placeComment,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.submitChallengeEvaluation(
          id,
          format: format,
          skipScore: skipScore,
          myGamesWon: myGamesWon,
          opponentGamesWon: opponentGamesWon,
          winnerUserId: winnerUserId,
          winnerTeam: winnerTeam,
          opponentRatings: opponentRatings,
          opponentPunctualityStars: opponentPunctualityStars,
          opponentComment: opponentComment,
          placeQualityStars: placeQualityStars,
          placeComment: placeComment,
        );
      }
      try {
        final isDoubles = format == ChallengeFormat.doubles;
        final response = await _dio.post<Map<String, dynamic>>(
          '/challenges/$id/evaluation',
          data: {
            'skip_score': skipScore,
            if (!skipScore) ...{
              'my_games_won': myGamesWon,
              'opponent_games_won': opponentGamesWon,
              if (isDoubles && winnerTeam != null && winnerTeam.length == 2)
                'winner_team': winnerTeam
              else if (!isDoubles)
                'winner_user_id': winnerUserId,
            },
            if (opponentRatings != null && opponentRatings.isNotEmpty)
              'opponent_ratings': opponentRatings.map((e) => e.toJson()).toList()
            else ...{
              'opponent_punctuality_stars': opponentPunctualityStars,
              if (opponentComment != null && opponentComment.isNotEmpty)
                'opponent_comment': opponentComment,
            },
            'place_quality_stars': ?placeQualityStars,
            if (placeComment != null && placeComment.isNotEmpty) 'place_comment': placeComment,
          },
        );
        final data = response.data;
        if (data != null && data.containsKey('id')) {
          return Challenge.fromJson(data);
        }
        return byId(id);
      } on DioException catch (e) {
        if (e.response?.statusCode == 409) {
          throw ApiException(
            e.response?.data is Map
                ? (e.response!.data['message'] as String? ??
                    'O resultado já foi informado por outro participante.')
                : 'O resultado já foi informado por outro participante.',
            statusCode: 409,
          );
        }
        rethrow;
      }
    });
  }

  Future<Challenge> approveResult(int id) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.approveChallengeResult(id);
      final response = await _dio.post<Map<String, dynamic>>('/challenges/$id/result/approve');
      final data = response.data;
      if (data != null && data.containsKey('id')) {
        return Challenge.fromJson(data);
      }
      return byId(id);
    });
  }

  Future<Challenge> _action(int id, String action) {
    return _guard(() async {
      if (Env.useMockApi) {
        if (action == 'cancel') return _mock.cancelChallenge(id);
        return _mock.challengeById(id);
      }
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
