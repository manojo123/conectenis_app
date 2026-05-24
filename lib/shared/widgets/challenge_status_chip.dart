import 'package:flutter/material.dart';
import 'package:conectenis_app/shared/models/enums.dart';

class ChallengeStatusChip extends StatelessWidget {
  const ChallengeStatusChip({super.key, required this.status});

  final ChallengeStatus status;

  Color get _color => switch (status) {
        ChallengeStatus.accepted ||
        ChallengeStatus.pendingScore ||
        ChallengeStatus.completed =>
          Colors.green,
        ChallengeStatus.cancelled || ChallengeStatus.declined => Colors.red,
        _ => Colors.blue,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(fontSize: 10, color: _color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
