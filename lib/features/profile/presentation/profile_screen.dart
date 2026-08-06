import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/core/theme/theme_mode_provider.dart';
import 'package:conectenis_app/features/home/models/dashboard_stats.dart';
import 'package:conectenis_app/features/home/providers/dashboard_providers.dart';
import 'package:conectenis_app/features/profile/providers/profile_feedback_provider.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:conectenis_app/shared/widgets/app_card.dart';
import 'package:conectenis_app/shared/widgets/app_switch.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/full_screen_image_viewer.dart';
import 'package:conectenis_app/shared/widgets/ntrp_stars.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';
import 'package:conectenis_app/shared/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(profileUpdatedNoticeProvider, (previous, next) {
      if (next && mounted) {
        ref.read(profileUpdatedNoticeProvider.notifier).state = false;
        showToast(context, 'Perfil atualizado com sucesso.');
        ref.invalidate(dashboardStatsProvider);
      }
    });

    final t = context.t;
    final user = ref.watch(authStateProvider).value;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final stats = statsAsync.valueOrNull;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final heroTag = user != null ? 'profile-avatar-${user.id}' : null;

    final subParts = <String>[
      if (user?.age != null) '${user!.age} anos',
      if ((user?.profession ?? '').isNotEmpty) user!.profession!,
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            await ref.read(authStateProvider.notifier).refreshUser();
          },
          child: ListView(
            padding:
                EdgeInsets.fromLTRB(14, 0, 14, screenBottomInset(context) + 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Perfil',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: t.text,
                        ),
                      ),
                    ),
                    PressableScale(
                      scale: 0.96,
                      onTap: () => context.push('/profile/edit'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: t.surface,
                          border: Border.all(color: t.border),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(Symbols.edit_rounded, size: 16, color: t.text),
                            const SizedBox(width: 6),
                            Text(
                              'Editar',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: t.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: user != null && user.displayAvatarUrl.isNotEmpty
                      ? () => showFullScreenImage(
                            context,
                            imageUrl: user.displayAvatarUrl,
                            heroTag: heroTag,
                          )
                      : null,
                  child: Hero(
                    tag: heroTag ?? 'profile-avatar',
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: t.accent, width: 3),
                      ),
                      child: UserAvatar(
                        name: user?.name ?? '',
                        email: user?.email,
                        avatarUrl: user?.avatarUrl,
                        hasCustomAvatar: user?.hasCustomAvatar ?? false,
                        userId: user?.id,
                        radius: 45,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.name ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: t.text,
                ),
              ),
              if (subParts.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subParts.join(' · '),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: t.muted),
                ),
              ],
              if (user?.city != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.location_on_rounded,
                        size: 15, fill: 1, color: t.accentText),
                    const SizedBox(width: 5),
                    Text(
                      '${user!.city}${user.state != null ? ', ${user.state}' : ''}',
                      style: TextStyle(fontSize: 12.5, color: t.muted),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              if (user != null) _ntrpCard(t, user.ntrpRating, stats),
              const SizedBox(height: 10),
              _statsGrid(t, stats, statsAsync.isLoading),
              const SizedBox(height: 16),
              _achievements(t, stats),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(14),
                radius: 16,
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                child: Row(
                  children: [
                    Icon(
                      isDark
                          ? Symbols.light_mode_rounded
                          : Symbols.dark_mode_rounded,
                      size: 20,
                      color: t.muted,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        isDark ? 'Tema escuro' : 'Tema claro',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                    ),
                    AppSwitch(
                      value: isDark,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(14),
                radius: 16,
                onTap: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                child: Row(
                  children: [
                    Icon(Symbols.logout_rounded, size: 20, color: t.error),
                    const SizedBox(width: 11),
                    Text(
                      'Sair da conta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: t.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ntrpCard(AppTokens t, double ntrp, DashboardStats? stats) {
    final local = stats?.ranking.local;
    return AppCard(
      onTap: () => context.push('/ranking'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    ntrpValueLabel(ntrp),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: t.accentText,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'NTRP · ${ntrpLevelName(ntrp)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: t.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              NtrpStars(value: ntrp, size: 22),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                local != null && local.rank != null
                    ? '${local.rankLabel}${local.cityName != null ? ' em ${local.cityName}' : ''}'
                    : 'Sem ranking ainda',
                style: TextStyle(
                  fontSize: local != null && local.rank != null ? 17 : 12.5,
                  fontWeight: FontWeight.w900,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Ver rankings',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: t.accentText,
                    ),
                  ),
                  Icon(Symbols.arrow_forward_rounded,
                      size: 15, color: t.accentText),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(AppTokens t, DashboardStats? stats, bool loading) {
    final record = stats?.record;
    String v(int? value) => loading ? '…' : '${value ?? 0}';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: v(record?.matchesPlayed),
                label: 'Partidas',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                value: v(record?.wins),
                label: 'Vitórias',
                valueColor: t.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: v(record?.losses),
                label: 'Derrotas',
                valueColor: t.error,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                value: loading ? '…' : (record?.winRatePercent ?? '0%'),
                label: 'Aproveitamento',
                valueColor: t.accentText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _achievements(AppTokens t, DashboardStats? stats) {
    final record = stats?.record;
    final localRank = stats?.ranking.local.rank;
    // Derived client-side until the backend exposes achievements
    // (see docs/BACKEND_PROMPT_REDESIGN.md).
    final achievements = <(IconData, String)>[
      if ((record?.wins ?? 0) >= 1)
        (Symbols.emoji_events_rounded, 'Primeira vitória'),
      if ((record?.wins ?? 0) >= 10)
        (Symbols.local_fire_department_rounded, '10 vitórias'),
      if ((record?.matchesPlayed ?? 0) >= 30)
        (Symbols.workspace_premium_rounded, '30 partidas'),
      if (localRank != null && localRank <= 15)
        (Symbols.military_tech_rounded, 'Top 15 na cidade'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 9),
          child: Text(
            'Conquistas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: t.text,
            ),
          ),
        ),
        if (achievements.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Jogue partidas avaliadas para desbloquear conquistas.',
              style: TextStyle(fontSize: 12.5, color: t.muted),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (icon, label) in achievements)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: t.surface,
                        border: Border.all(color: t.border),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 17, fill: 1, color: t.warning),
                          const SizedBox(width: 7),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: t.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
