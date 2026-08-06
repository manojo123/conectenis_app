import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

/// Prototype choice chips: selected = lime pill w/ dark text, unselected =
/// surface + border + muted. Wraps by default; `scrollable` for long rows.
class ChoiceChipRow extends StatelessWidget {
  const ChoiceChipRow({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.scrollable = false,
    this.radius = 999,
    this.dense = false,
  });

  final List<String> options;

  /// -1 for "nothing selected".
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool scrollable;
  final double radius;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (var i = 0; i < options.length; i++) _chip(context, i),
    ];
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (i, chip) in chips.indexed) ...[
              if (i > 0) SizedBox(width: dense ? 6 : 8),
              chip,
            ],
          ],
        ),
      );
    }
    return Wrap(
      spacing: dense ? 6 : 8,
      runSpacing: dense ? 6 : 8,
      children: chips,
    );
  }

  Widget _chip(BuildContext context, int i) {
    final t = context.t;
    final selected = i == selectedIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 13 : 16,
          vertical: dense ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: selected ? t.accent : t.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected ? Colors.transparent : t.border,
          ),
        ),
        child: Text(
          options[i],
          style: TextStyle(
            fontSize: dense ? 12 : 13.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? t.onAccent : t.muted,
          ),
        ),
      ),
    );
  }
}
