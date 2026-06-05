import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';
import 'package:conectenis_app/shared/models/message.dart';

/// A challenge info panel shown in chat (not a deletable message).
class ChatChallengeEvent {
  const ChatChallengeEvent({
    required this.challengeId,
    required this.status,
    required this.createdAt,
    this.summary,
  });

  final int challengeId;
  final ChallengeStatus status;
  final DateTime createdAt;
  final String? summary;

  factory ChatChallengeEvent.fromJson(Map<String, dynamic> json) {
    return ChatChallengeEvent(
      challengeId: parseJsonInt(json['challenge_id']),
      status: ChallengeStatus.fromValue(json['challenge_status'] as String?),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      summary: json['summary'] as String?,
    );
  }
}

sealed class ChatTimelineEntry {
  DateTime get sortAt;
}

class ChatMessageTimelineEntry extends ChatTimelineEntry {
  ChatMessageTimelineEntry(this.message);

  final Message message;

  @override
  DateTime get sortAt => message.createdAt;
}

class ChatChallengeTimelineEntry extends ChatTimelineEntry {
  ChatChallengeTimelineEntry(this.event);

  final ChatChallengeEvent event;

  @override
  DateTime get sortAt => event.createdAt;
}

List<ChatTimelineEntry> mergeChatTimeline({
  required List<Message> messages,
  required List<ChatChallengeEvent> challenges,
}) {
  final items = <ChatTimelineEntry>[
    ...messages.map(ChatMessageTimelineEntry.new),
    ...challenges.map(ChatChallengeTimelineEntry.new),
  ];
  items.sort((a, b) => a.sortAt.compareTo(b.sortAt));
  return items;
}
