import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';

/// NTRP 1.0–5.0 in 0.5 steps (half-star UI).
class NtrpRatingPicker extends StatelessWidget {
  const NtrpRatingPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double size;

  static const double minRating = 1.0;
  static const double maxRating = 5.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            final filled = value >= starValue;
            final half = !filled && value >= starValue - 0.5;

            return SizedBox(
              width: size + 8,
              height: size + 8,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    filled
                        ? Icons.star
                        : half
                            ? Icons.star_half
                            : Icons.star_border,
                    color: AppColors.lime,
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
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                'Iniciante',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'NTRP ${value.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.lime),
            ),
            Expanded(
              child: Text(
                'Avançado',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
