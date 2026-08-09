import 'package:conectenis_app/shared/models/json_parsers.dart';

/// A single member of a `type: "group"` conversation (doubles thread) -
/// see docs/BACKEND_PROMPT_REDESIGN.md §10. Absent/empty on `direct` rows.
class ConversationParticipant {
  const ConversationParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? avatarUrl;

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: parseJsonInt(json['id']),
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.lastMessage,
    this.updatedAt,
    this.otherAvatarUrl,
    this.unreadCount = 0,
    this.lastMessageSenderId,
    this.type = 'direct',
    this.challengeId,
    this.title,
    this.participants = const [],
    this.isArchived = false,
  });

  final int id;
  final int otherUserId;
  final String otherUserName;
  final String? lastMessage;
  final DateTime? updatedAt;
  final String? otherAvatarUrl;

  /// Unread messages for the current user. Optional server field
  /// (`unread_count`) - see docs/BACKEND_PROMPT_REDESIGN.md; 0 when absent.
  final int unreadCount;

  /// Who sent [lastMessage]. Optional server field (`last_message_user_id`)
  /// - see docs/BACKEND_PROMPT_REDESIGN.md; null when absent, in which case
  /// the UI shows the preview with no "Você:"/name prefix.
  final int? lastMessageSenderId;

  /// `'direct'` (today's 1:1 rows) or `'group'` (doubles thread, §10).
  final String type;

  bool get isGroup => type == 'group';

  /// Doubles challenge this group thread belongs to. Only set for `group`.
  final int? challengeId;

  /// Group row label (e.g. the place name) - null on `direct` rows.
  final String? title;

  /// All members of a `group` thread, including the requesting user.
  /// Empty on `direct` rows (use [otherUserId]/[otherUserName] there).
  final List<ConversationParticipant> participants;

  /// Group thread is read-only once its challenge reaches a terminal
  /// status. Always false for `direct` rows.
  final bool isArchived;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: parseJsonInt(json['id']),
      otherUserId: parseJsonInt(json['other_user_id']),
      otherUserName: json['other_user_name'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      otherAvatarUrl: json['other_avatar_url'] as String?,
      unreadCount: parseJsonInt(json['unread_count']),
      lastMessageSenderId: json['last_message_user_id'] == null
          ? null
          : parseJsonInt(json['last_message_user_id']),
      type: json['type'] as String? ?? 'direct',
      challengeId: json['challenge_id'] == null
          ? null
          : parseJsonInt(json['challenge_id']),
      title: json['title'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) =>
                  ConversationParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isArchived: json['is_archived'] == true,
    );
  }
}
