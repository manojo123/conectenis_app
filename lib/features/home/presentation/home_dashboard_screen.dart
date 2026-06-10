import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/features/home/presentation/widgets/matchmaking_card.dart';
import 'package:conectenis_app/features/home/presentation/widgets/stats_panel.dart';
import 'package:conectenis_app/features/home/providers/dashboard_providers.dart';
import 'package:conectenis_app/shared/widgets/app_top_bar.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardStatsProvider);
    await Future.wait([
      ref.read(dashboardStatsProvider.future),
      ref.read(dashboardMatchmakingProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: AppTopBar()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Início',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: const SliverToBoxAdapter(child: MatchmakingCard()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: const SliverToBoxAdapter(child: StatsPanel()),
            ),
          ],
        ),
      ),
    );
  }
}
