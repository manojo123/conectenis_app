import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_radii.dart';
import 'package:conectenis_app/core/theme/semantic_colors.dart';
import 'package:conectenis_app/shared/models/enums.dart';

class ChallengeStatusChip extends StatelessWidget {
  const ChallengeStatusChip({super.key, required this.status});

  final ChallengeStatus status;

  @override
  Widget build(BuildContext context) {
    final color = SemanticColors.forChallengeStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
