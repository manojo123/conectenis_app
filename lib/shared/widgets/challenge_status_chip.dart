import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/semantic_colors.dart';
import 'package:conectenis_app/shared/models/enums.dart';

class ChallengeStatusChip extends StatelessWidget {
  const ChallengeStatusChip({super.key, required this.status});

  final ChallengeStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = SemanticColors.forChallengeStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: t.tintFor(color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
          color: color,
        ),
      ),
    );
  }
}
