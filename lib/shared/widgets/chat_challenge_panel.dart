import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/shared/models/chat_timeline_entry.dart';
import 'package:conectenis_app/shared/models/enums.dart';

class ChatChallengePanel extends StatelessWidget {
  const ChatChallengePanel({super.key, required this.event});

  final ChatChallengeEvent event;

  Color get _color => switch (event.status) {
        ChallengeStatus.accepted ||
        ChallengeStatus.pendingScore ||
        ChallengeStatus.completed =>
          Colors.green,
        ChallengeStatus.pendingResultApproval => Colors.orange,
        ChallengeStatus.cancelled || ChallengeStatus.declined => Colors.red,
        _ => Colors.blue,
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/challenges/${event.challengeId}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _color, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.sports_tennis, color: _color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.summary ?? 'Desafio de tênis',
                        style: TextStyle(
                          color: _color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        event.status.label,
                        style: TextStyle(color: _color.withValues(alpha: 0.9), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: _color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
