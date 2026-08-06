import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

/// Translucent blurred chrome (nav bar, floating pills, pinned bottom bars) —
/// the prototype's `background:var(--nav-bg);backdrop-filter:blur(14px)`.
class Frosted extends StatelessWidget {
  const Frosted({
    super.key,
    required this.child,
    this.borderRadius,
    this.color,
    this.border,
    this.boxShadow,
    this.sigma = 14,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final Color? color;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? context.t.navBg,
            borderRadius: borderRadius,
            border: border,
          ),
          child: child,
        ),
      ),
    );
    if (boxShadow == null) return content;
    // Shadows must be painted OUTSIDE the clip that bounds the blur.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: content,
    );
  }
}
