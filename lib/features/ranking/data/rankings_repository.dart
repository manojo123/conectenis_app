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
    this.matchesPlayed,
  });

  final int rank;
  final int wins;
  final int points;
  final Player player;
  final String? cityName;
  final String? state;
  final int? matchesPlayed;
}

class RankingUserPosition {
  const RankingUserPosition({
    required this.rank,
    required this.points,
    required this.wins,
    this.matchesPlayed,
  });

  final int rank;
  final int points;
  final int wins;
  final int? matchesPlayed;

  factory RankingUserPosition.fromJson(Map<String, dynamic> json) {
    return RankingUserPosition(
      rank: parseJsonInt(json['rank']),
      points: parseJsonInt(json['points']),
      wins: parseJsonInt(json['wins']),
      matchesPlayed: json['matches_played'] as int?,
    );
  }
}

class RankingsResponse {
  const RankingsResponse({
    required this.entries,
    this.segmentLabel,
    this.userPosition,
  });

  final List<RankingEntry> entries;
  final String? segmentLabel;
  final RankingUserPosition? userPosition;
}

class RankingsRepository {
  RankingsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<RankingsResponse> fetch({
    required RankingGeoScope geo,
    required double ntrpLevel,
    required RankingGenderFilter gender,
    required ChallengeFormat format,
    String? state,
    int? cityId,
    String country = 'BR',
  }) async {
    if (Env.useMockApi) {
      final entries = List.generate(5, (i) {
        return RankingEntry(
          rank: i + 1,
          wins: 30 - i * 3,
          points: 500 - i * 50,
          matchesPlayed: 35 - i * 3,
          player: Player(
            id: i + 1,
            name: 'Jogador ${i + 1}',
            latitude: 0,
            longitude: 0,
            ntrpRating: ntrpLevel,
            gender: gender == RankingGenderFilter.female ? Gender.female : Gender.male,
          ),
        );
      });
      return RankingsResponse(
        entries: entries,
        segmentLabel:
            '${format.label} · NTRP ${ntrpLevel.toStringAsFixed(1)} · ${gender.label} · ${geo.label}',
        userPosition: const RankingUserPosition(rank: 12, points: 275, wins: 3, matchesPlayed: 5),
      );
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/rankings',
        queryParameters: {
          'geo': geo.value,
          'ntrp_level': ntrpLevel,
          'gender': gender.value,
          'format': format.value,
          'state': ?state,
          'city_id': ?cityId,
          'country': country,
        },
      );
      final data = response.data ?? {};
      final list = data['data'] as List<dynamic>? ?? [];
      final entries = list.map((e) {
        final map = e as Map<String, dynamic>;
        final playerMap = map['player'] as Map<String, dynamic>;
        final cityMap = map['city'] as Map<String, dynamic>?;
        return RankingEntry(
          rank: parseJsonInt(map['rank']),
          wins: parseJsonInt(map['wins']),
          points: parseJsonInt(map['points']),
          matchesPlayed: map['matches_played'] as int?,
          player: Player.fromJson(playerMap),
          cityName: cityMap?['name'] as String?,
          state: cityMap?['state'] as String?,
        );
      }).toList();

      final userPosJson = data['user_position'] as Map<String, dynamic>?;
      return RankingsResponse(
        entries: entries,
        segmentLabel: data['segment_label'] as String?,
        userPosition:
            userPosJson != null ? RankingUserPosition.fromJson(userPosJson) : null,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Legacy fetch for backward compatibility during API transition.
  Future<List<RankingEntry>> fetchLegacy({
    required RankingScope scope,
    int? cityId,
    String? state,
    String country = 'BR',
  }) async {
    if (Env.useMockApi) {
      return (await fetch(
        geo: RankingGeoScope.city,
        ntrpLevel: 4.0,
        gender: RankingGenderFilter.all,
        format: ChallengeFormat.singles,
      ))
          .entries;
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
