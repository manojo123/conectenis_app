import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';
import 'package:conectenis_app/shared/utils/player_mapper.dart';

final playersRepositoryProvider = Provider<PlayersRepository>((ref) {
  return PlayersRepository(
    dio: ref.watch(dioProvider),
    mock: ref.watch(mockApiServiceProvider),
    getCurrentUser: () => ref.read(authStateProvider).value,
  );
});

class PlayersRepository {
  PlayersRepository({
    required Dio dio,
    required MockApiService mock,
    required UserProfile? Function() getCurrentUser,
  })  : _dio = dio,
        _mock = mock,
        _getCurrentUser = getCurrentUser;

  final Dio _dio;
  final MockApiService _mock;
  final UserProfile? Function() _getCurrentUser;

  Future<List<Player>> nearby({
    required double lat,
    required double lng,
    String? name,
    String? city,
    Gender? gender,
    double? minNtrp,
    double? maxNtrp,
    int? minAge,
    int? maxAge,
    String sort = 'distance',
    double radiusKm = 50,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.nearbyPlayers(
          lat: lat,
          lng: lng,
          name: name,
          gender: gender,
          minNtrp: minNtrp,
          maxNtrp: maxNtrp,
          minAge: minAge,
          maxAge: maxAge,
        );
      }
      final response = await _dio.get<List<dynamic>>(
        '/players/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radiusKm,
          if (name != null && name.isNotEmpty) 'name': name,
          if (city != null && city.isNotEmpty) 'city': city,
          if (gender != null) 'gender': gender.value,
          'min_ntrp': ?minNtrp,
          'max_ntrp': ?maxNtrp,
          'min_age': ?minAge,
          'max_age': ?maxAge,
          'sort': sort,
        },
      );
      return (response.data ?? [])
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Player?> byId(int id) {
    return _guard(() async {
      final self = _getCurrentUser();
      if (self != null && self.id == id) {
        return playerFromUserProfile(self);
      }
      if (Env.useMockApi) {
        final player = await _mock.playerById(id);
        if (player != null) return player;
        if (self != null && self.id == id) {
          return playerFromUserProfile(self);
        }
        return null;
      }
      try {
        final response = await _dio.get<Map<String, dynamic>>('/players/$id');
        return Player.fromJson(response.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 && self != null && self.id == id) {
          return playerFromUserProfile(self);
        }
        rethrow;
      }
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
