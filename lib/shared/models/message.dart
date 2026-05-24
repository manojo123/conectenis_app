import 'package:conectenis_app/shared/models/json_parsers.dart';

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.isMine = false,
  });

  final int id;
  final int conversationId;
  final int userId;
  final String body;
  final DateTime createdAt;
  final bool isMine;

  Message copyWith({bool? isMine}) => Message(
        id: id,
        conversationId: conversationId,
        userId: userId,
        body: body,
        createdAt: createdAt,
        isMine: isMine ?? this.isMine,
      );

  factory Message.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final userId = parseJsonInt(json['user_id']);
    return Message(
      id: parseJsonInt(json['id']),
      conversationId: parseJsonInt(json['conversation_id']),
      userId: userId,
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      isMine: currentUserId != null && userId == currentUserId,
    );
  }
}
