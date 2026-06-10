import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';

/// Branded "Conec" + "Tênis" wordmark per logo guidelines.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.style,
    this.showLogo = false,
    this.logoHeight = 36,
  });

  final TextStyle? style;
  final bool showLogo;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conecColor = isDark ? AppColors.white : AppColors.navy;
    final baseStyle = style ??
        Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ) ??
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 20);

    final wordmark = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Conec', style: baseStyle.copyWith(color: conecColor)),
          TextSpan(
            text: 'Tênis',
            style: baseStyle.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );

    if (!showLogo) return wordmark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_conectenis.png',
          height: logoHeight,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        wordmark,
      ],
    );
  }
}

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
