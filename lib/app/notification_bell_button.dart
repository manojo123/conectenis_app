import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/app/nav_badges.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/shared/widgets/frosted.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';

/// Bell icon with an unread badge that opens Notificações - lives in each
/// tab's header now that the bottom nav no longer has a dedicated tab for it.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key, this.frosted = false, this.size = 40});

  final bool frosted;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final unread = ref.watch(unreadNotificationsCountProvider);
    void open() => context.push('/notifications');

    final Widget button;
    if (frosted) {
      button = Frosted(
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: t.border),
        boxShadow: t.shadow,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: open,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(Symbols.notifications_rounded, size: 20, color: t.muted),
          ),
        ),
      );
    } else {
      button = CircleIconButton(
        icon: Symbols.notifications_rounded,
        size: size,
        onTap: open,
        tooltip: 'Notificações',
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        if (unread > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16),
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.bg, width: 2),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
