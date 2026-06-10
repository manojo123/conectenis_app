import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/shared/models/enums.dart';

/// Maps challenge/match statuses to brand semantic colors.
abstract final class SemanticColors {
  static Color forChallengeStatus(ChallengeStatus status) => switch (status) {
        ChallengeStatus.accepted ||
        ChallengeStatus.pendingScore ||
        ChallengeStatus.completed =>
          AppColors.success,
        ChallengeStatus.pendingResultApproval => AppColors.warning,
        ChallengeStatus.cancelled || ChallengeStatus.declined => AppColors.error,
        _ => AppColors.info,
      };

  static Color forWinLoss({required bool isWin}) =>
      isWin ? AppColors.success : AppColors.error;
}
