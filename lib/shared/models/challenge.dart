import 'package:conectenis_app/shared/models/challenge_result.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/utils/challenge_status_labels.dart';

class Challenge {
  const Challenge({
    required this.id,
    required this.type,
    required this.format,
    this.scoringFormat = ScoringFormat.bestOfThreeSets,
    required this.status,
    required this.scheduledStart,
    required this.creator,
    this.scheduledEnd,
    this.message,
    this.openLocation = false,
    this.minNtrp,
    this.maxNtrp,
    this.genderPreference,
    this.professionPreference,
    this.slotsTotal = 2,
    this.place,
    this.participants = const [],
    this.candidatesCount = 0,
    this.role,
    this.hasSubmittedEvaluation = false,
    this.result,
    this.canSubmitResult = false,
    this.canApproveResult = false,
    this.canRejectResult = false,
    this.creatorTeam,
    this.statusLabel,
    this.declinedReason,
    this.cancelledReason,
    this.closedReason,
    this.distanceKm,
    this.canApply = false,
    this.hasApplied = false,
  });

  final int id;
  final ChallengeType type;
  final ChallengeFormat format;

  /// Set/tiebreak rules for the match result - distinct from [format]
  /// (singles/doubles). See docs/BACKEND_PROMPT_REDESIGN.md §12.
  final ScoringFormat scoringFormat;
  final ChallengeStatus status;
  final DateTime scheduledStart;
  final DateTime? scheduledEnd;
  final String? message;
  final bool openLocation;
  final double? minNtrp;
  final double? maxNtrp;
  final String? genderPreference;
  final String? professionPreference;
  final int slotsTotal;
  final Player creator;
  final Place? place;
  final List<ChallengeParticipant> participants;
  final int candidatesCount;
  final String? role;
  final bool hasSubmittedEvaluation;
  final ChallengeResult? result;
  final bool canSubmitResult;
  final bool canApproveResult;
  final bool canRejectResult;
  final int? creatorTeam;
  final String? statusLabel;
  final String? declinedReason;
  final String? cancelledReason;
  final String? closedReason;
  final double? distanceKm;
  final bool canApply;
  final bool hasApplied;

  String get displayStatusLabel => challengeDisplayStatusLabel(
        status: status,
        apiStatusLabel: statusLabel,
        declinedReason: declinedReason,
        cancelledReason: cancelledReason,
        closedReason: closedReason,
      );

  List<ChallengeParticipant> get candidates =>
      participants.where((p) => p.role == 'candidate').toList();

  bool get canEditAsCreator =>
      type == ChallengeType.public && status == ChallengeStatus.pendingCandidates;

  /// All distinct user ids in this challenge (creator + non-candidate participants).
  List<int> get participantUserIds {
    final ids = <int>{creator.id};
    for (final p in participants) {
      if (p.role == 'candidate') continue;
      ids.add(p.user.id);
    }
    return ids.toList();
  }

  int get requiredApprovalCount => participantUserIds.length;

  bool get hasProposedResult => result != null;

  bool get isResultLocked =>
      status == ChallengeStatus.completed || status == ChallengeStatus.pendingResultApproval;

  bool get hasTeamData =>
      creatorTeam != null || participants.any((p) => p.team != null);

  bool hasUserApprovedResult(int userId) => result?.hasUserApproved(userId) ?? false;

  String? participantName(int userId) {
    if (creator.id == userId) return creator.name;
    for (final p in participants) {
      if (p.user.id == userId) return p.user.name;
    }
    return null;
  }

  Player? participantPlayer(int userId) {
    if (creator.id == userId) return creator;
    for (final p in participants) {
      if (p.user.id == userId) return p.user;
    }
    return null;
  }

  int? teamForUserId(int userId) {
    if (userId == creator.id) return creatorTeam ?? _teamFromParticipants(userId);
    for (final p in participants) {
      if (p.user.id == userId) return p.team;
    }
    return null;
  }

  int? _teamFromParticipants(int userId) {
    for (final p in participants) {
      if (p.user.id == userId) return p.team;
    }
    return null;
  }

  List<int> teamUserIds(int team) {
    final ids = <int>[];
    if (teamForUserId(creator.id) == team) ids.add(creator.id);
    for (final p in participants) {
      if (teamForUserId(p.user.id) == team) ids.add(p.user.id);
    }
    return ids;
  }

  List<int> myTeamUserIds(int currentUserId) {
    final myTeam = teamForUserId(currentUserId);
    if (myTeam != null && hasTeamData) {
      return teamUserIds(myTeam);
    }
    return _fallbackMyTeam(currentUserId);
  }

  List<int> opponentTeamUserIds(int currentUserId) {
    final myTeam = teamForUserId(currentUserId);
    if (myTeam != null && hasTeamData) {
      final otherTeam = myTeam == 1 ? 2 : 1;
      return teamUserIds(otherTeam);
    }
    return _fallbackOpponentTeam(currentUserId);
  }

  List<int> _fallbackMyTeam(int currentUserId) {
    if (format == ChallengeFormat.singles) return [currentUserId];
    final others = participantUserIds.where((id) => id != currentUserId).toList();
    if (others.isEmpty) return [currentUserId];
    return [currentUserId, others.first];
  }

  List<int> _fallbackOpponentTeam(int currentUserId) {
    final mine = _fallbackMyTeam(currentUserId).toSet();
    return participantUserIds.where((id) => !mine.contains(id)).toList();
  }

  List<List<Player>> teamsForDisplay() {
    if (format == ChallengeFormat.singles) {
      final ids = participantUserIds;
      if (ids.length >= 2) {
        return [
          [participantPlayer(ids[0])!],
          [participantPlayer(ids[1])!],
        ];
      }
      return [
        [creator],
        if (participants.isNotEmpty) [participants.first.user] else [creator],
      ];
    }

    if (hasTeamData) {
      final team1 = teamUserIds(1).map(participantPlayer).whereType<Player>().toList();
      final team2 = teamUserIds(2).map(participantPlayer).whereType<Player>().toList();
      if (team1.isNotEmpty && team2.isNotEmpty) return [team1, team2];
    }

    final all = participantUserIds.map(participantPlayer).whereType<Player>().toList();
    if (all.length >= 4) {
      return [all.sublist(0, 2), all.sublist(2, 4)];
    }
    if (all.length >= 2) {
      return [all.sublist(0, 1), all.sublist(1)];
    }
    return [[creator], if (participants.isNotEmpty) [participants.first.user] else []];
  }

  Challenge copyWith({
    ChallengeStatus? status,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String? message,
    bool? openLocation,
    double? minNtrp,
    double? maxNtrp,
    String? genderPreference,
    String? professionPreference,
    Place? place,
    List<ChallengeParticipant>? participants,
    int? candidatesCount,
    String? role,
    bool? hasSubmittedEvaluation,
    ChallengeResult? result,
    bool clearResult = false,
    bool? canSubmitResult,
    bool? canApproveResult,
    bool? canRejectResult,
    String? statusLabel,
    String? declinedReason,
    String? cancelledReason,
    String? closedReason,
    double? distanceKm,
    bool? canApply,
    bool? hasApplied,
  }) {
    return Challenge(
      id: id,
      type: type,
      format: format,
      status: status ?? this.status,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      message: message ?? this.message,
      openLocation: openLocation ?? this.openLocation,
      minNtrp: minNtrp ?? this.minNtrp,
      maxNtrp: maxNtrp ?? this.maxNtrp,
      genderPreference: genderPreference ?? this.genderPreference,
      professionPreference: professionPreference ?? this.professionPreference,
      slotsTotal: slotsTotal,
      creator: creator,
      creatorTeam: creatorTeam,
      place: place ?? this.place,
      participants: participants ?? this.participants,
      candidatesCount: candidatesCount ?? this.candidatesCount,
      role: role ?? this.role,
      hasSubmittedEvaluation: hasSubmittedEvaluation ?? this.hasSubmittedEvaluation,
      result: clearResult ? null : (result ?? this.result),
      canSubmitResult: canSubmitResult ?? this.canSubmitResult,
      canApproveResult: canApproveResult ?? this.canApproveResult,
      canRejectResult: canRejectResult ?? this.canRejectResult,
      statusLabel: statusLabel ?? this.statusLabel,
      declinedReason: declinedReason ?? this.declinedReason,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      closedReason: closedReason ?? this.closedReason,
      distanceKm: distanceKm ?? this.distanceKm,
      canApply: canApply ?? this.canApply,
      hasApplied: hasApplied ?? this.hasApplied,
    );
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final creatorJson = json['creator'] as Map<String, dynamic>;
    return Challenge(
      id: parseJsonInt(json['id']),
      type: ChallengeType.fromValue(json['type'] as String?),
      format: ChallengeFormat.fromValue(json['format'] as String?),
      scoringFormat: ScoringFormat.fromValue(json['scoring_format'] as String?),
      status: ChallengeStatus.fromValue(json['status'] as String?),
      scheduledStart: DateTime.parse(json['scheduled_start'] as String),
      scheduledEnd: json['scheduled_end'] != null
          ? DateTime.tryParse(json['scheduled_end'] as String)
          : null,
      message: json['message'] as String?,
      openLocation: json['open_location'] == true,
      minNtrp: json['min_ntrp'] == null ? null : parseJsonDouble(json['min_ntrp']),
      maxNtrp: json['max_ntrp'] == null ? null : parseJsonDouble(json['max_ntrp']),
      genderPreference: json['gender_preference'] as String?,
      professionPreference: json['profession_preference'] as String?,
      slotsTotal: parseJsonInt(json['slots_total'] ?? 2),
      creator: Player.fromJson(creatorJson),
      creatorTeam: _parseTeam(creatorJson['team'] ?? json['creator_team']),
      place: json['place'] != null
          ? Place.fromJson(json['place'] as Map<String, dynamic>)
          : null,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => ChallengeParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      candidatesCount: parseJsonInt(json['candidates_count'] ?? 0),
      role: json['role'] as String?,
      hasSubmittedEvaluation: json['has_submitted_evaluation'] == true,
      result: json['result'] != null
          ? ChallengeResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      canSubmitResult: json['can_submit_result'] == true,
      canApproveResult: json['can_approve_result'] == true,
      canRejectResult: json['can_reject_result'] == true,
      statusLabel: json['status_label'] as String?,
      declinedReason: json['declined_reason'] as String?,
      cancelledReason: json['cancelled_reason'] as String?,
      closedReason: json['closed_reason'] as String?,
      distanceKm: json['distance_km'] == null
          ? null
          : parseJsonDouble(json['distance_km']),
      canApply: json['can_apply'] == true,
      hasApplied: json['has_applied'] == true,
    );
  }

  static int? _parseTeam(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value == '1' || value == 'home') return 1;
      if (value == '2' || value == 'away') return 2;
    }
    return parseJsonInt(value);
  }
}

class ChallengeParticipant {
  const ChallengeParticipant({
    required this.id,
    required this.role,
    required this.status,
    required this.user,
    this.team,
  });

  final int id;
  final String role;
  final String status;
  final Player user;
  final int? team;

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipant(
      id: parseJsonInt(json['id']),
      role: json['role'] as String? ?? '',
      status: json['status'] as String? ?? '',
      user: Player.fromJson(json['user'] as Map<String, dynamic>),
      team: Challenge._parseTeam(json['team'] ?? json['side']),
    );
  }
}

/// Payload item for evaluation submit.
class OpponentRatingPayload {
  const OpponentRatingPayload({
    required this.userId,
    required this.punctualityStars,
    required this.fairPlayStars,
    required this.communicationStars,
    this.comment,
  });

  final int userId;
  final int punctualityStars;
  final int fairPlayStars;
  final int communicationStars;
  final String? comment;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'punctuality_stars': punctualityStars,
        'fair_play_stars': fairPlayStars,
        'communication_stars': communicationStars,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };
}
