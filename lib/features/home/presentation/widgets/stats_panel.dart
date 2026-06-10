import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/core/theme/app_radii.dart';
import 'package:conectenis_app/features/home/models/dashboard_stats.dart';
import 'package:conectenis_app/features/home/presentation/widgets/rating_evolution_chart.dart';
import 'package:conectenis_app/features/home/providers/dashboard_providers.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class StatsPanel extends ConsumerWidget {
  const StatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const _StatsShell(
        child: SizedBox(height: 280, child: LoadingView()),
      ),
      error: (error, _) => _StatsShell(
        child: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(dashboardStatsProvider),
        ),
      ),
      data: (stats) => _StatsPanelContent(stats: stats),
    );
  }
}

class _StatsShell extends StatelessWidget {
  const _StatsShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: scheme.outline),
      ),
      child: child,
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_tennis, color: scheme.onSurface, size: 20),
              const SizedBox(width: 8),
              Text(
                'MINHAS ESTATÍSTICAS',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _CircularStat(
                  value: record.winRatePercent,
                  label: 'Vitórias',
                  borderColor: AppColors.success,
                ),
              ),
              Expanded(
                child: _CircularStat(
                  value: record.lossRatePercent,
                  label: 'Derrotas',
                  borderColor: AppColors.info,
                ),
              ),
              Expanded(
                child: _CircularStat(
                  value: '${record.matchesPlayed}',
                  label: 'Desafios',
                  borderColor: scheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Rating Atual:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          Text(
            ntrp.toStringAsFixed(1),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => context.go('/ranking-tab'),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Local ${local.rankLabel} · Geral ${general.rankLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                      decoration: TextDecoration.underline,
                      decorationColor: scheme.outline,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          RatingEvolutionChart(points: stats.effectiveRatingHistory),
        ],
      ),
    );
  }
}

class _CircularStat extends StatelessWidget {
  const _CircularStat({
    required this.value,
    required this.label,
    required this.borderColor,
  });

  final String value;
  final String label;
  final Color borderColor;
  static const _borderWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: _borderWidth),
            color: scheme.surfaceContainerHighest,
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }
}
