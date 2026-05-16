class MatchRecord {
  const MatchRecord({
    required this.id,
    required this.opponentId,
    required this.opponentName,
    required this.playerScore,
    required this.opponentScore,
    required this.won,
    required this.playedAt,
  });

  final int id;
  final int opponentId;
  final String opponentName;
  final int playerScore;
  final int opponentScore;
  final bool won;
  final DateTime playedAt;

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    return MatchRecord(
      id: json['id'] as int,
      opponentId: json['opponent_id'] as int,
      opponentName: json['opponent_name'] as String,
      playerScore: json['player_score'] as int,
      opponentScore: json['opponent_score'] as int,
      won: json['won'] as bool,
      playedAt: DateTime.parse(json['played_at'] as String),
    );
  }
}

class RivalStats {
  const RivalStats({
    required this.opponentId,
    required this.opponentName,
    required this.wins,
    required this.losses,
  });

  final int opponentId;
  final String opponentName;
  final int wins;
  final int losses;

  factory RivalStats.fromJson(Map<String, dynamic> json) {
    return RivalStats(
      opponentId: json['opponent_id'] as int,
      opponentName: json['opponent_name'] as String,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
    );
  }
}
