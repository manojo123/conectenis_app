import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/core/theme/app_shadows.dart';

class LimeButton extends StatelessWidget {
  const LimeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.outlined = false,
    this.danger = false,
    this.glow = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;
  /// Red outline/text for destructive actions (e.g. cancel challenge).
  final bool danger;
  /// Lime glow shadow — use on the single primary CTA per screen.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined
                  ? (danger ? AppColors.error : AppColors.primary)
                  : AppColors.onPrimary,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(label.toUpperCase()),
            ],
          );

    if (outlined) {
      final style = danger
          ? OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            )
          : null;
      return OutlinedButton(
        style: style,
        onPressed: loading ? null : onPressed,
        child: child,
      );
    }

    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: child,
    );

    if (!glow) return button;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null && !loading ? AppShadows.limeGlow : null,
      ),
      child: button,
    );
  }
}
