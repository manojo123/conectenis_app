import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/challenge_result.dart';
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
    Set<ChallengeStatus>? statuses,
    DateTime? scheduledFrom,
    DateTime? scheduledTo,
    bool includeHistory = false,
    ChallengeListSort sort = ChallengeListSort.priority,
    int? radiusKm,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.challenges(
          role: role,
          statuses: statuses,
          scheduledFrom: scheduledFrom,
          scheduledTo: scheduledTo,
          includeHistory: includeHistory,
          sort: sort,
          radiusKm: radiusKm,
        );
      }
      final params = <String, dynamic>{
        'role': role.value,
        'include_history': includeHistory,
        'sort': sort.value,
        if (statuses != null && statuses.isNotEmpty)
          'status': statuses.map((s) => s.value).toList(),
        if (scheduledFrom != null) 'scheduled_from': scheduledFrom.toIso8601String(),
        if (scheduledTo != null) 'scheduled_to': scheduledTo.toIso8601String(),
        'radius_km': ?radiusKm,
      };
      final response = await _dio.get<List<dynamic>>(
        '/challenges',
        queryParameters: params,
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
    ScoringFormat scoringFormat = ScoringFormat.bestOfThreeSets,
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
          scoringFormat: scoringFormat,
          participantIds: participantIds,
          placeId: placeId,
          googlePlaceId: googlePlaceId,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/challenges/direct',
        data: {
          'format': format.value,
          'scoring_format': scoringFormat.value,
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
    ScoringFormat scoringFormat = ScoringFormat.bestOfThreeSets,
    int? placeId,
    String? googlePlaceId,
    bool openLocation = false,
    required DateTime scheduledStart,
    DateTime? scheduledEnd,
    String? message,
    double? minNtrp,
    double? maxNtrp,
    Gender? genderPreference,
    String? professionPreference,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.createPublicChallenge(
          format: format,
          scoringFormat: scoringFormat,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          placeId: placeId,
          googlePlaceId: googlePlaceId,
          openLocation: openLocation,
          minNtrp: minNtrp,
          maxNtrp: maxNtrp,
          genderPreference: genderPreference?.value,
          professionPreference: professionPreference,
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/challenges/public',
        data: {
          'format': format.value,
          'scoring_format': scoringFormat.value,
          'place_id': ?placeId,
          'google_place_id': ?googlePlaceId,
          'open_location': openLocation,
          'scheduled_start': scheduledStart.toIso8601String(),
          if (scheduledEnd != null) 'scheduled_end': scheduledEnd.toIso8601String(),
          'message': ?message,
          'min_ntrp': ?minNtrp,
          'max_ntrp': ?maxNtrp,
          if (genderPreference != null) 'gender_preference': genderPreference.value,
          if (professionPreference != null && professionPreference.isNotEmpty)
            'profession_preference': professionPreference,
        },
      );
      return Challenge.fromJson(response.data!);
    });
  }

  Future<Challenge> updatePublic({
    required int id,
    String? message,
    int? placeId,
    String? googlePlaceId,
    bool? openLocation,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    double? minNtrp,
    double? maxNtrp,
    Gender? genderPreference,
    String? professionPreference,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.updatePublicChallenge(
          id,
          message: message,
          placeId: placeId,
          googlePlaceId: googlePlaceId,
          openLocation: openLocation,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          minNtrp: minNtrp,
          maxNtrp: maxNtrp,
          genderPreference: genderPreference?.value,
          professionPreference: professionPreference,
        );
      }
      final response = await _dio.put<Map<String, dynamic>>(
        '/challenges/$id',
        data: {
          'message': ?message,
          'place_id': ?placeId,
          'google_place_id': ?googlePlaceId,
          'open_location': ?openLocation,
          if (scheduledStart != null) 'scheduled_start': scheduledStart.toIso8601String(),
          if (scheduledEnd != null) 'scheduled_end': scheduledEnd.toIso8601String(),
          'min_ntrp': ?minNtrp,
          'max_ntrp': ?maxNtrp,
          if (genderPreference != null) 'gender_preference': genderPreference.value,
          'profession_preference': ?professionPreference,
        },
      );
      return Challenge.fromJson(response.data!);
    });
  }

  Future<List<ChallengeParticipant>> listCandidates(int id) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.listChallengeCandidates(id);
      final response = await _dio.get<List<dynamic>>('/challenges/$id/candidates');
      return (response.data ?? [])
          .map((e) => ChallengeParticipant.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Challenge> acceptCandidate(int challengeId, int userId) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.acceptChallengeCandidate(challengeId, userId);
      final response = await _dio.post<Map<String, dynamic>>(
        '/challenges/$challengeId/candidates/$userId/accept',
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
    List<SetScore>? sets,
    TiebreakScore? superTiebreak,
    int? winnerUserId,
    List<int>? winnerTeam,
    List<OpponentRatingPayload>? opponentRatings,
    int? opponentPunctualityStars,
    int? opponentFairPlayStars,
    int? opponentCommunicationStars,
    String? opponentComment,
    int? courtQualityStars,
    int? infrastructureStars,
    int? placeQualityStars,
    String? placeComment,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.submitChallengeEvaluation(
          id,
          format: format,
          skipScore: skipScore,
          sets: sets,
          superTiebreak: superTiebreak,
          winnerUserId: winnerUserId,
          winnerTeam: winnerTeam,
          opponentRatings: opponentRatings,
          opponentPunctualityStars: opponentPunctualityStars,
          opponentFairPlayStars: opponentFairPlayStars,
          opponentCommunicationStars: opponentCommunicationStars,
          opponentComment: opponentComment,
          courtQualityStars: courtQualityStars,
          infrastructureStars: infrastructureStars,
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
              'sets': sets?.map((s) => s.toJson()).toList(),
              'super_tiebreak': superTiebreak?.toJson(),
              if (isDoubles && winnerTeam != null && winnerTeam.length == 2)
                'winner_team': winnerTeam
              else if (!isDoubles)
                'winner_user_id': winnerUserId,
            },
            if (opponentRatings != null && opponentRatings.isNotEmpty)
              'opponent_ratings': opponentRatings.map((e) => e.toJson()).toList()
            else ...{
              'opponent_punctuality_stars': opponentPunctualityStars,
              'opponent_fair_play_stars': opponentFairPlayStars,
              'opponent_communication_stars': opponentCommunicationStars,
              if (opponentComment != null && opponentComment.isNotEmpty)
                'opponent_comment': opponentComment,
            },
            'court_quality_stars': ?courtQualityStars,
            'infrastructure_stars': ?infrastructureStars,
            'place_quality_stars': ?placeQualityStars ?? courtQualityStars,
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

  Future<Challenge> rejectResult(int id) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.rejectChallengeResult(id);
      final response = await _dio.post<Map<String, dynamic>>('/challenges/$id/result/reject');
      final data = response.data;
      if (data != null && data.containsKey('id')) {
        return Challenge.fromJson(data);
      }
      return byId(id);
    });
  }

  Future<Challenge> approveResult(
    int id, {
    List<OpponentRatingPayload>? opponentRatings,
    int? courtQualityStars,
    int? infrastructureStars,
    String? placeComment,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.approveChallengeResult(
          id,
          opponentRatings: opponentRatings,
          courtQualityStars: courtQualityStars,
          infrastructureStars: infrastructureStars,
          placeComment: placeComment,
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/challenges/$id/result/approve',
        data: {
          if (opponentRatings != null && opponentRatings.isNotEmpty)
            'opponent_ratings': opponentRatings.map((e) => e.toJson()).toList(),
          'court_quality_stars': ?courtQualityStars,
          'infrastructure_stars': ?infrastructureStars,
          if (placeComment != null && placeComment.isNotEmpty) 'place_comment': placeComment,
        },
      );
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
        return switch (action) {
          'accept' => _mock.acceptChallenge(id),
          'decline' => _mock.declineChallenge(id),
          'apply' => _mock.applyToChallenge(id),
          'cancel' => _mock.cancelChallenge(id),
          _ => _mock.challengeById(id),
        };
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
