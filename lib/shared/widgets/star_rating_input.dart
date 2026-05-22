import 'package:flutter/material.dart';

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final star = index + 1;
        return IconButton(
          icon: Icon(
            star <= value ? Icons.star : Icons.star_border,
            color: Colors.amber.shade700,
            size: size,
          ),
          onPressed: () => onChanged(star),
        );
      }),
    );
  }
}
