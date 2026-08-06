import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

/// Display-only half-star row for an NTRP value (1.0–5.0).
/// For the interactive picker use [NtrpRatingPicker].
class NtrpStars extends StatelessWidget {
  const NtrpStars({
    super.key,
    required this.value,
    this.size = 24,
    this.color,
  });

  final double value;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final active = color ?? t.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          _star(i, active, t.disabled),
      ],
    );
  }

  Widget _star(int position, Color active, Color inactive) {
    final full = value >= position;
    final half = !full && value >= position - 0.5;
    return Icon(
      half ? Symbols.star_half_rounded : Symbols.star_rounded,
      size: size,
      fill: full || half ? 1 : 0,
      color: full || half ? active : inactive,
    );
  }
}
