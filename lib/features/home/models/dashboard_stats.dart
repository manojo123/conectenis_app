import 'package:conectenis_app/shared/models/json_parsers.dart';

class DashboardStats {
  const DashboardStats({
    required this.tennisLevel,
    required this.record,
    required this.ranking,
  });

  final DashboardTennisLevel tennisLevel;
  final DashboardMatchRecord record;
  final DashboardRankingSnapshot ranking;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      tennisLevel: DashboardTennisLevel.fromJson(
        json['tennis_level'] as Map<String, dynamic>? ?? const {},
      ),
      record: DashboardMatchRecord.fromJson(
        json['record'] as Map<String, dynamic>? ?? const {},
      ),
      ranking: DashboardRankingSnapshot.fromJson(
        json['ranking'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class DashboardTennisLevel {
  const DashboardTennisLevel({required this.ntrpRating});

  final double ntrpRating;

  factory DashboardTennisLevel.fromJson(Map<String, dynamic> json) {
    return DashboardTennisLevel(
      ntrpRating: parseJsonDouble(json['ntrp_rating'], fallback: 3.0),
    );
  }
}

class DashboardMatchRecord {
  const DashboardMatchRecord({
    required this.wins,
    required this.losses,
    required this.matchesPlayed,
    required this.winRate,
  });

  final int wins;
  final int losses;
  final int matchesPlayed;
  final double winRate;

  factory DashboardMatchRecord.fromJson(Map<String, dynamic> json) {
    return DashboardMatchRecord(
      wins: parseJsonInt(json['wins']),
      losses: parseJsonInt(json['losses']),
      matchesPlayed: parseJsonInt(json['matches_played']),
      winRate: parseJsonDouble(json['win_rate']),
    );
  }

  String get winRatePercent {
    if (matchesPlayed == 0) return '0%';
    return '${(winRate * 100).toStringAsFixed(1)}%';
  }
}

class DashboardRankingSnapshot {
  const DashboardRankingSnapshot({
    required this.local,
    required this.general,
  });

  final DashboardRankingPosition local;
  final DashboardRankingPosition general;

  factory DashboardRankingSnapshot.fromJson(Map<String, dynamic> json) {
    return DashboardRankingSnapshot(
      local: DashboardRankingPosition.fromJson(
        json['local'] as Map<String, dynamic>? ?? const {},
      ),
      general: DashboardRankingPosition.fromJson(
        json['general'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class DashboardRankingPosition {
  const DashboardRankingPosition({
    required this.scope,
    this.cityId,
    this.cityName,
    this.state,
    this.rank,
    this.totalPlayers = 0,
    this.points = 0,
  });

  final String scope;
  final int? cityId;
  final String? cityName;
  final String? state;
  final int? rank;
  final int totalPlayers;
  final int points;

  factory DashboardRankingPosition.fromJson(Map<String, dynamic> json) {
    final rankValue = json['rank'];
    return DashboardRankingPosition(
      scope: json['scope'] as String? ?? '',
      cityId: json['city_id'] != null ? parseJsonInt(json['city_id']) : null,
      cityName: json['city_name'] as String?,
      state: json['state'] as String?,
      rank: rankValue == null ? null : parseJsonInt(rankValue),
      totalPlayers: parseJsonInt(json['total_players']),
      points: parseJsonInt(json['points']),
    );
  }

  String get rankLabel => rank != null ? '#$rank' : '—';
}
