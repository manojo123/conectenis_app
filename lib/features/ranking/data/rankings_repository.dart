import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';

final rankingsRepositoryProvider = Provider<RankingsRepository>((ref) {
  return RankingsRepository(dio: ref.watch(dioProvider));
});

class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.wins,
    required this.points,
    required this.player,
    this.cityName,
    this.state,
  });

  final int rank;
  final int wins;
  final int points;
  final Player player;
  final String? cityName;
  final String? state;
}

class RankingsRepository {
  RankingsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<RankingEntry>> fetch({
    required RankingScope scope,
    int? cityId,
    String? state,
    String country = 'BR',
  }) async {
    if (Env.useMockApi) {
      return List.generate(5, (i) {
        return RankingEntry(
          rank: i + 1,
          wins: 30 - i * 3,
          points: 300 - i * 30,
          player: Player(
            id: i + 1,
            name: 'Jogador ${i + 1}',
            latitude: 0,
            longitude: 0,
            ntrpRating: 4.0 - i * 0.5,
          ),
        );
      });
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/rankings',
        queryParameters: {
          'scope': scope.value,
          'city_id': ?cityId,
          'state': ?state,
          'country': country,
        },
      );
      final list = response.data?['data'] as List<dynamic>? ?? [];
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        final playerMap = map['player'] as Map<String, dynamic>;
        final cityMap = map['city'] as Map<String, dynamic>?;
        return RankingEntry(
          rank: parseJsonInt(map['rank']),
          wins: parseJsonInt(map['wins']),
          points: parseJsonInt(map['points']),
          player: Player.fromJson(playerMap),
          cityName: cityMap?['name'] as String?,
          state: cityMap?['state'] as String?,
        );
      }).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
