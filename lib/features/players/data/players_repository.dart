import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/player.dart';

final playersRepositoryProvider = Provider<PlayersRepository>((ref) {
  return PlayersRepository(
    dio: ref.watch(dioProvider),
    mock: ref.watch(mockApiServiceProvider),
  );
});

class PlayersRepository {
  PlayersRepository({required Dio dio, required MockApiService mock})
      : _dio = dio,
        _mock = mock;

  final Dio _dio;
  final MockApiService _mock;

  Future<List<Player>> nearby({
    required double lat,
    required double lng,
    SkillLevel? skill,
    int? minAge,
    int? maxAge,
  }) async {
    if (Env.useMockApi) {
      return _mock.nearbyPlayers(
        lat: lat,
        lng: lng,
        skill: skill,
        minAge: minAge,
        maxAge: maxAge,
      );
    }
    final response = await _dio.get<List<dynamic>>(
      '/players/nearby',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': 25,
        if (skill != null) 'skill_level': skill.value,
        'min_age': ?minAge,
        'max_age': ?maxAge,
      },
    );
    return (response.data ?? [])
        .map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Player?> byId(int id) async {
    if (Env.useMockApi) return _mock.playerById(id);
    final response = await _dio.get<Map<String, dynamic>>('/players/$id');
    return Player.fromJson(response.data!);
  }
}
