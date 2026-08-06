import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

/// Prototype stat tile: big w900 value over a small muted label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
    this.dense = false,
  });

  final String value;
  final String label;
  final Color? valueColor;

  /// Compact 4-in-a-row variant (player profile).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(vertical: 12, horizontal: 6)
          : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(dense ? 14 : 16),
      ),
      child: Column(
        crossAxisAlignment:
            dense ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: dense ? 19 : 23,
              fontWeight: FontWeight.w900,
              color: valueColor ?? t.text,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dense ? 10 : 11.5,
              fontWeight: FontWeight.w700,
              color: t.muted,
            ),
          ),
        ],
      ),
    );
  }
}
