import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/theme_mode_provider.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/widgets/brand_logo.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final unread = user?.unreadNotificationsCount ?? 0;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          const BrandLogo(variant: BrandLogoVariant.horizontal, height: 36),
          const Spacer(),
          IconButton(
            tooltip: isDark ? 'Tema claro' : 'Tema escuro',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
          IconButton(
            tooltip: 'Mensagens',
            onPressed: () => context.go('/messages'),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            tooltip: 'Notificações',
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => context.push('/profile'),
            icon: UserAvatar(
              name: user?.name ?? '?',
              avatarUrl: user?.avatarUrl,
              email: user?.email,
              hasCustomAvatar: user?.hasCustomAvatar ?? false,
              radius: 14,
            ),
          ),
        ],
      ),
    );
  }
}
