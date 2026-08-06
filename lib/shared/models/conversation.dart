import 'package:conectenis_app/shared/models/json_parsers.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.lastMessage,
    this.updatedAt,
    this.otherAvatarUrl,
    this.unreadCount = 0,
  });

  final int id;
  final int otherUserId;
  final String otherUserName;
  final String? lastMessage;
  final DateTime? updatedAt;
  final String? otherAvatarUrl;

  /// Unread messages for the current user. Optional server field
  /// (`unread_count`) — see docs/BACKEND_PROMPT_REDESIGN.md; 0 when absent.
  final int unreadCount;

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
    );
  }
}
