import 'package:conectenis_app/shared/models/json_parsers.dart';

class ChallengeResultApproval {
  const ChallengeResultApproval({
    required this.userId,
    required this.userName,
    required this.approved,
    this.approvedAt,
  });

  final int userId;
  final String userName;
  final bool approved;
  final DateTime? approvedAt;

  factory ChallengeResultApproval.fromJson(Map<String, dynamic> json) {
    return ChallengeResultApproval(
      userId: parseJsonInt(json['user_id']),
      userName: json['user_name'] as String? ?? json['name'] as String? ?? '',
      approved: json['approved'] == true,
      approvedAt: json['approved_at'] == null
          ? null
          : DateTime.tryParse(json['approved_at'] as String),
    );
  }
}

class OpponentResultRating {
  const OpponentResultRating({
    required this.userId,
    required this.userName,
    required this.punctualityStars,
    this.fairPlayStars,
    this.communicationStars,
    this.comment,
  });

  final int userId;
  final String userName;
  final int punctualityStars;
  final int? fairPlayStars;
  final int? communicationStars;
  final String? comment;

  factory OpponentResultRating.fromJson(Map<String, dynamic> json) {
    return OpponentResultRating(
      userId: parseJsonInt(json['user_id']),
      userName: json['user_name'] as String? ?? json['name'] as String? ?? '',
      punctualityStars: parseJsonInt(json['punctuality_stars'] ?? json['stars']),
      fairPlayStars: json['fair_play_stars'] == null
          ? null
          : parseJsonInt(json['fair_play_stars']),
      communicationStars: json['communication_stars'] == null
          ? null
          : parseJsonInt(json['communication_stars']),
      comment: json['comment'] as String?,
    );
  }
}

/// Proposed match result awaiting approval from all participants.
class ChallengeResult {
  const ChallengeResult({
    required this.skipScore,
    this.winnerUserId,
    this.winnerTeamIds = const [],
    this.winnerName,
    this.winnerTeamLabel,
    this.scoreLabel,
    this.submittedByUserId,
    this.submittedByName,
    this.myGamesWon,
    this.opponentGamesWon,
    this.approvals = const [],
    this.opponentPunctualityStars,
    this.opponentComment,
    this.opponentRatings = const [],
    this.placeQualityStars,
    this.courtQualityStars,
    this.infrastructureStars,
    this.placeComment,
    this.proposedAt,
    this.autoAcceptAt,
  });

  final bool skipScore;
  final int? winnerUserId;
  final List<int> winnerTeamIds;
  final String? winnerName;
  final String? winnerTeamLabel;
  final String? scoreLabel;
  final int? submittedByUserId;
  final String? submittedByName;
  final int? myGamesWon;
  final int? opponentGamesWon;
  final List<ChallengeResultApproval> approvals;
  final int? opponentPunctualityStars;
  final String? opponentComment;
  final List<OpponentResultRating> opponentRatings;
  final int? placeQualityStars;
  final int? courtQualityStars;
  final int? infrastructureStars;
  final String? placeComment;
  final DateTime? proposedAt;
  final DateTime? autoAcceptAt;

  Duration? timeUntilAutoAccept(DateTime now) {
    if (autoAcceptAt == null) return null;
    final remaining = autoAcceptAt!.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool hasUserApproved(int userId) =>
      approvals.any((a) => a.userId == userId && a.approved);

  int approvalCount(int totalParticipants) =>
      approvals.where((a) => a.approved).length;

  factory ChallengeResult.fromJson(Map<String, dynamic> json) {
    final winnerTeamRaw = json['winner_team'];
    List<int> winnerTeamIds = const [];
    if (winnerTeamRaw is List) {
      winnerTeamIds = winnerTeamRaw.map((e) => parseJsonInt(e)).toList();
    }

    return ChallengeResult(
      skipScore: json['skip_score'] == true,
      winnerUserId: json['winner_user_id'] as int?,
      winnerTeamIds: winnerTeamIds,
      winnerName: json['winner_name'] as String?,
      winnerTeamLabel: json['winner_team_label'] as String?,
      scoreLabel: json['score_label'] as String?,
      submittedByUserId: json['submitted_by_user_id'] as int?,
      submittedByName: json['submitted_by_name'] as String?,
      myGamesWon: json['my_games_won'] as int?,
      opponentGamesWon: json['opponent_games_won'] as int?,
      approvals: (json['approvals'] as List<dynamic>?)
              ?.map((e) => ChallengeResultApproval.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      opponentPunctualityStars: json['opponent_punctuality_stars'] as int?,
      opponentComment: json['opponent_comment'] as String?,
      opponentRatings: (json['opponent_ratings'] as List<dynamic>?)
              ?.map((e) => OpponentResultRating.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      placeQualityStars: json['place_quality_stars'] as int?,
      courtQualityStars: json['court_quality_stars'] as int?,
      infrastructureStars: json['infrastructure_stars'] as int?,
      placeComment: json['place_comment'] as String?,
      proposedAt: json['proposed_at'] == null
          ? null
          : DateTime.tryParse(json['proposed_at'] as String),
      autoAcceptAt: json['auto_accept_at'] == null
          ? null
          : DateTime.tryParse(json['auto_accept_at'] as String),
    );
  }
}
