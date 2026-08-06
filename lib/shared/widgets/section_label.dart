import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

/// Prototype section heading ("Formato", "Data") — 13px w800.
/// [SectionLabel.caps] is the small uppercase variant (CIDADE, SET 1).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing})
      : _caps = false;

  const SectionLabel.caps(this.text, {super.key, this.trailing})
      : _caps = true;

  final String text;
  final Widget? trailing;
  final bool _caps;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final label = Text(
      _caps ? text.toUpperCase() : text,
      style: _caps
          ? TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: t.disabled,
            )
          : TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: t.text,
            ),
    );
    if (trailing == null) return label;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [label, trailing!],
    );
  }
}
