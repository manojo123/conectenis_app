import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

/// 40px circle icon button (surface + border) — prototype back/close/actions.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final button = Material(
      color: t.surface,
      shape: CircleBorder(side: BorderSide(color: t.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: color ?? t.text),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Pushed-screen header: back/close circle + w900 title + optional trailing.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.close = false,
    this.trailing,
  });

  final String title;

  /// Defaults to `context.pop()`.
  final VoidCallback? onBack;

  /// Renders an X instead of a back arrow (modal-style screens).
  final bool close;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
        color: t.text,
      ),
    );
    final back = CircleIconButton(
      icon: close ? Symbols.close_rounded : Symbols.arrow_back_rounded,
      onTap: onBack ?? () => context.pop(),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: close
          ? Row(
              children: [
                Expanded(child: titleText),
                if (trailing != null) ...[trailing!, const SizedBox(width: 10)],
                back,
              ],
            )
          : Row(
              children: [
                back,
                const SizedBox(width: 12),
                Expanded(child: titleText),
                ?trailing,
              ],
            ),
    );
  }
}

/// Tab-screen header: big w900 title (+ optional subtitle) + trailing actions.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: t.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12.5, color: t.muted),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
