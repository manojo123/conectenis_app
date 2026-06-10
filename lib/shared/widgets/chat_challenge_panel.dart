import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/core/theme/app_radii.dart';
import 'package:conectenis_app/core/theme/semantic_colors.dart';
import 'package:conectenis_app/shared/models/chat_timeline_entry.dart';

class ChatChallengePanel extends StatelessWidget {
  const ChatChallengePanel({super.key, required this.event});

  final ChatChallengeEvent event;

  @override
  Widget build(BuildContext context) {
    final color = SemanticColors.forChallengeStatus(event.status);
    return Center(
      child: Material(
        color: AppColors.navyDeep.withValues(alpha: 0),
        child: InkWell(
          onTap: () => context.push('/challenges/${event.challengeId}'),
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.sports_tennis, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.summary ?? 'Desafio de tênis',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        event.status.label,
                        style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
