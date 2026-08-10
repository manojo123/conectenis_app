import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/app/nav_badges.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/shared/widgets/frosted.dart';

/// Approximate height of the frosted nav bar (excluding the device inset).
/// Screens that draw behind it add this to their bottom padding.
const kNavBarHeight = 74.0;

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NOTE: flipped to true in the map-tab redesign phase, once every tab
      // pads its scroll content by kNavBarHeight.
      extendBody: false,
      body: SafeArea(bottom: false, child: navigationShell),
      bottomNavigationBar: _CtNavBar(shell: navigationShell),
    );
  }
}

class _CtNavBar extends ConsumerWidget {
  const _CtNavBar({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final messages = ref.watch(unreadMessagesCountProvider).valueOrNull ?? 0;
    final challenges = ref.watch(pendingChallengesCountProvider).valueOrNull ?? 0;

    // Icon, label, badge count, shell branch index.
    final items = <(IconData, String, int, int)>[
      (Symbols.map_rounded, 'Mapa', 0, 0),
      (Symbols.chat_bubble_rounded, 'Mensagens', messages, 1),
      (Symbols.sports_tennis_rounded, 'Desafios', challenges, 2),
      (Symbols.leaderboard_rounded, 'Ranking', 0, 3),
      (Symbols.person_rounded, 'Perfil', 0, 4),
    ];

    return Frosted(
      border: Border(top: BorderSide(color: t.border)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 12),
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _NavItem(
                    icon: item.$1,
                    label: item.$2,
                    badge: item.$3,
                    active: shell.currentIndex == item.$4,
                    onTap: () => shell.goBranch(
                      item.$4,
                      initialLocation: item.$4 == shell.currentIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.badge,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int badge;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = active ? t.accentText : t.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                  fill: active ? 1 : 0,
                  weight: 500,
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -9,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
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
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
