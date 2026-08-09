import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

/// Prototype info rows.
///
/// Plain: `icon + muted text` (challenge card schedule/place lines).
/// [InfoRow.labeled]: accent icon + caps label over value (+ optional meta),
/// the QUANDO / ONDE / FORMATO rows on the challenge detail.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.text})
      : label = null,
        value = null,
        meta = null;

  const InfoRow.labeled({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.meta,
  }) : text = null;

  final IconData icon;
  final String? text;
  final String? label;
  final String? value;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (text != null) {
      return Row(
        children: [
          Icon(icon, size: 17, color: t.disabled),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: t.muted),
            ),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 19, color: t.accentText),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label!.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.disabled,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value!,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              if (meta != null) ...[
                const SizedBox(height: 1),
                Text(
                  meta!,
                  style: TextStyle(fontSize: 11.5, color: t.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
