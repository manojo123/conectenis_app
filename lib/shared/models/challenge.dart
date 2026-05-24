import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/models/player.dart';

class Challenge {
  const Challenge({
    required this.id,
    required this.type,
    required this.format,
    required this.status,
    required this.scheduledStart,
    required this.creator,
    this.scheduledEnd,
    this.message,
    this.openLocation = false,
    this.minNtrp,
    this.maxNtrp,
    this.genderPreference,
    this.slotsTotal = 2,
    this.place,
    this.participants = const [],
    this.candidatesCount = 0,
    this.role,
    this.hasSubmittedEvaluation = false,
  });

  final int id;
  final ChallengeType type;
  final ChallengeFormat format;
  final ChallengeStatus status;
  final DateTime scheduledStart;
  final DateTime? scheduledEnd;
  final String? message;
  final bool openLocation;
  final double? minNtrp;
  final double? maxNtrp;
  final String? genderPreference;
  final int slotsTotal;
  final Player creator;
  final Place? place;
  final List<ChallengeParticipant> participants;
  final int candidatesCount;
  final String? role;
  final bool hasSubmittedEvaluation;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: parseJsonInt(json['id']),
      type: ChallengeType.fromValue(json['type'] as String?),
      format: ChallengeFormat.fromValue(json['format'] as String?),
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
      slotsTotal: parseJsonInt(json['slots_total'] ?? 2),
      creator: Player.fromJson(json['creator'] as Map<String, dynamic>),
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
    );
  }
}

class ChallengeParticipant {
  const ChallengeParticipant({
    required this.id,
    required this.role,
    required this.status,
    required this.user,
  });

  final int id;
  final String role;
  final String status;
  final Player user;

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipant(
      id: parseJsonInt(json['id']),
      role: json['role'] as String? ?? '',
      status: json['status'] as String? ?? '',
      user: Player.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
