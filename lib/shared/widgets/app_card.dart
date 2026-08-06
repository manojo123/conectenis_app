import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';

/// Prototype surface card: `background:var(--surface);border:1px solid
/// var(--border);border-radius:16–18`. Tappable cards get the press-scale.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.radius = 18,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1,
    this.color,
    this.gradient,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? t.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? t.border, width: borderWidth),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return PressableScale(onTap: onTap, scale: 0.985, child: card);
  }
}
