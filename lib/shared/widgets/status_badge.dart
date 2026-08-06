import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

enum BadgeKind { accent, info, success, warning, error, neutral }

/// Prototype badge chip: tinted bg, 9.5px w900 caps, radius 8, no border.
/// Used for challenge kind/format/outcome labels (DIRETO, SIMPLES, VITÓRIA…).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.kind = BadgeKind.neutral});

  const StatusBadge.accent(this.label, {super.key}) : kind = BadgeKind.accent;
  const StatusBadge.info(this.label, {super.key}) : kind = BadgeKind.info;
  const StatusBadge.success(this.label, {super.key}) : kind = BadgeKind.success;
  const StatusBadge.warning(this.label, {super.key}) : kind = BadgeKind.warning;
  const StatusBadge.error(this.label, {super.key}) : kind = BadgeKind.error;

  final String label;
  final BadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (bg, fg) = switch (kind) {
      BadgeKind.accent => (t.tintAcc, t.accentText),
      BadgeKind.info => (t.tintInfo, t.info),
      BadgeKind.success => (t.tintSucc, t.success),
      BadgeKind.warning => (t.tintWarn, t.warning),
      BadgeKind.error => (t.tintErr, t.error),
      BadgeKind.neutral => (t.surface2, t.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
          color: fg,
        ),
      ),
    );
  }
}
