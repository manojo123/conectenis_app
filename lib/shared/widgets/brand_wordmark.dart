import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';

/// Inline brand span for body copy mentioning ConecTenis.
InlineSpan brandTextSpan(BuildContext context, {TextStyle? style}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final conecColor = isDark ? AppColors.white : AppColors.navy;
  final base = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  return TextSpan(
    children: [
      TextSpan(text: 'Conec', style: base.copyWith(color: conecColor, fontWeight: FontWeight.w600)),
      TextSpan(text: 'Tênis', style: base.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
    ],
  );
}
