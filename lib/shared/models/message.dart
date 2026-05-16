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
    final userId = json['user_id'] as int;
    return Message(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      userId: userId,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isMine: currentUserId != null && userId == currentUserId,
    );
  }
}
