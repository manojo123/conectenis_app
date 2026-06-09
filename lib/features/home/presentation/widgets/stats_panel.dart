import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/features/home/models/dashboard_stats.dart';
import 'package:conectenis_app/features/home/providers/dashboard_providers.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class StatsPanel extends ConsumerWidget {
  const StatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const _StatsPanelShell(
        child: SizedBox(
          height: 180,
          child: LoadingView(),
        ),
      ),
      error: (error, _) => _StatsPanelShell(
        child: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(dashboardStatsProvider),
        ),
      ),
      data: (stats) => _StatsPanelContent(stats: stats),
    );
  }
}

class _StatsPanelShell extends StatelessWidget {
  const _StatsPanelShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _StatsPanelContent extends StatelessWidget {
  const _StatsPanelContent({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final ntrp = stats.tennisLevel.ntrpRating;
    final record = stats.record;
    final local = stats.ranking.local;
    final general = stats.ranking.general;

    return Card(
      color: AppColors.card,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.lime.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_tennis, color: AppColors.lime, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Nível $ntrp',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.lime,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Suas estatísticas',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _RankTile(
                    label: 'Ranking Local',
                    subtitle: local.cityName ?? 'Sua cidade',
                    rank: local.rankLabel,
                    onTap: () => context.go('/ranking-tab'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RankTile(
                    label: 'Ranking Geral',
                    subtitle: general.state ?? 'Estado',
                    rank: general.rankLabel,
                    onTap: () => context.go('/ranking-tab'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Vitórias',
                    value: '${record.wins}',
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    label: 'Derrotas',
                    value: '${record.losses}',
                    icon: Icons.close_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    label: 'Aproveit.',
                    value: record.winRatePercent,
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.label,
    required this.subtitle,
    required this.rank,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final String rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                rank,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.lime,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.lime, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
