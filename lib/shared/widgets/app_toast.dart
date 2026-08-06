import 'dart:async';

import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

/// Prototype toast: floating inverted pill above the bottom nav, auto-dismiss.
/// Replaces SnackBars on redesigned screens: `showToast(context, 'Feito!')`.
void showToast(BuildContext context, String message) =>
    AppToast.show(context, message);

abstract final class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(BuildContext context, String message) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    dismiss();
    final entry = OverlayEntry(
      builder: (context) => _ToastOverlay(message: message),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(milliseconds: 2600), dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastOverlay extends StatelessWidget {
  const _ToastOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 98 + bottomInset,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - value)),
              child: child,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.86,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.toastBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: t.shadow,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: t.toastFg,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
