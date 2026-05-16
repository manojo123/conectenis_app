class Conversation {
  const Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.lastMessage,
    this.updatedAt,
    this.otherAvatarUrl,
  });

  final int id;
  final int otherUserId;
  final String otherUserName;
  final String? lastMessage;
  final DateTime? updatedAt;
  final String? otherAvatarUrl;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      otherUserId: json['other_user_id'] as int,
      otherUserName: json['other_user_name'] as String,
      lastMessage: json['last_message'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      otherAvatarUrl: json['other_avatar_url'] as String?,
    );
  }
}
