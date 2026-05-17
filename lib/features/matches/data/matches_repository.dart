import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/shared/models/match_record.dart';

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return MatchesRepository(
    dio: ref.watch(dioProvider),
    mock: ref.watch(mockApiServiceProvider),
  );
});

class MatchesRepository {
  MatchesRepository({required Dio dio, required MockApiService mock})
      : _dio = dio,
        _mock = mock;

  final Dio _dio;
  final MockApiService _mock;

  Future<List<MatchRecord>> list() async {
    if (Env.useMockApi) return _mock.matches();
    final response = await _dio.get<List<dynamic>>('/matches');
    return (response.data ?? [])
        .map((e) => MatchRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RivalStats>> rivals() async {
    if (Env.useMockApi) return _mock.rivals();
    final response = await _dio.get<List<dynamic>>('/matches/rivals');
    return (response.data ?? [])
        .map((e) => RivalStats.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MatchRecord> log({
    required int opponentId,
    required String opponentName,
    required int playerScore,
    required int opponentScore,
    required bool won,
  }) async {
    if (Env.useMockApi) {
      return _mock.logMatch(
        opponentId: opponentId,
        opponentName: opponentName,
        playerScore: playerScore,
        opponentScore: opponentScore,
        won: won,
      );
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/matches',
      data: {
        'opponent_id': opponentId,
        'player_score': playerScore,
        'opponent_score': opponentScore,
        'won': won,
      },
    );
    return MatchRecord.fromJson(response.data!);
  }
}
