import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

/// NTRP 1.0–5.0 in 0.5 steps (half-star picker, prototype lime stars).
class NtrpRatingPicker extends StatelessWidget {
  const NtrpRatingPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
    this.showScale = true,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double size;

  /// Shows the "Iniciante / NTRP x,x / Avançado" caption row.
  final bool showScale;

  static const double minRating = 1.0;
  static const double maxRating = 5.0;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            final filled = value >= starValue;
            final half = !filled && value >= starValue - 0.5;

            return SizedBox(
              width: size + 6,
              height: size + 6,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    half ? Symbols.star_half_rounded : Symbols.star_rounded,
                    fill: filled || half ? 1 : 0,
                    color: filled || half ? t.accent : t.disabled,
                    size: size,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => onChanged(starValue - 0.5),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => onChanged(starValue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
        if (showScale) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Iniciante',
                  style: TextStyle(fontSize: 12, color: t.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'NTRP ${value.toStringAsFixed(1).replaceAll('.', ',')}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: t.text,
                ),
              ),
              Expanded(
                child: Text(
                  'Avançado',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 12, color: t.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
