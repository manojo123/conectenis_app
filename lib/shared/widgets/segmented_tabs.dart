import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/shared/widgets/frosted.dart';

/// Prototype segmented control: surface container with equal-flex segments,
/// active = lime pill with dark text. `frosted: true` renders the floating
/// map variant (blurred translucent pill).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.frosted = false,
    this.dense = false,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final bool frosted;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final radius = frosted ? 999.0 : 14.0;
    final segmentRadius = frosted ? 999.0 : 10.0;

    final row = Row(
      mainAxisSize: frosted ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (var i = 0; i < labels.length; i++)
          _segment(context, t, i, segmentRadius),
      ],
    );

    if (frosted) {
      return Frosted(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: t.border),
        boxShadow: t.shadow,
        child: Padding(padding: const EdgeInsets.all(5), child: row),
      );
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: row,
    );
  }

  Widget _segment(BuildContext context, AppTokens t, int i, double radius) {
    final selected = i == index;
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          vertical: dense ? 8 : 10,
          horizontal: frosted ? 16 : 2,
        ),
        decoration: BoxDecoration(
          color: selected ? t.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Text(
          labels[i],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: dense ? 11.5 : 12.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? t.onAccent : t.muted,
          ),
        ),
      ),
    );
    return frosted ? child : Expanded(child: child);
  }
}
