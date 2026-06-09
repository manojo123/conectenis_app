import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/features/home/presentation/widgets/matchmaking_card.dart';
import 'package:conectenis_app/features/home/presentation/widgets/stats_panel.dart';
import 'package:conectenis_app/features/home/providers/dashboard_providers.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(dashboardMatchmakingProvider);
    await Future.wait([
      ref.read(dashboardStatsProvider.future),
      ref.read(dashboardMatchmakingProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            StatsPanel(),
            SizedBox(height: 16),
            MatchmakingCard(),
          ],
        ),
      ),
    );
  }
}
