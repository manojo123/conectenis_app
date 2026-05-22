import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/models/player.dart';

class PlayInvitation {
  const PlayInvitation({
    required this.id,
    required this.status,
    required this.scheduledAt,
    required this.inviter,
    required this.invitee,
    required this.place,
    this.message,
    this.completedAt,
    this.completedByUserId,
    this.role,
    this.hasRatedOpponent = false,
    this.createdAt,
  });

  final int id;
  final PlayInvitationStatus status;
  final DateTime scheduledAt;
  final String? message;
  final DateTime? completedAt;
  final int? completedByUserId;
  final Player inviter;
  final Player invitee;
  final Place place;
  final String? role;
  final bool hasRatedOpponent;
  final DateTime? createdAt;

  Player opponentFor(int currentUserId) {
    return inviter.id == currentUserId ? invitee : inviter;
  }

  bool isInviter(int currentUserId) => inviter.id == currentUserId;

  factory PlayInvitation.fromJson(Map<String, dynamic> json) {
    return PlayInvitation(
      id: parseJsonInt(json['id']),
      status: PlayInvitationStatus.fromValue(json['status'] as String?),
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      message: json['message'] as String?,
      completedAt: _parseDateTime(json['completed_at']),
      completedByUserId: json['completed_by_user_id'] == null
          ? null
          : parseJsonInt(json['completed_by_user_id']),
      inviter: Player.fromJson(json['inviter'] as Map<String, dynamic>),
      invitee: Player.fromJson(json['invitee'] as Map<String, dynamic>),
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      role: json['role'] as String?,
      hasRatedOpponent: json['has_rated_opponent'] == true,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
