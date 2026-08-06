import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/features/home/data/dashboard_repository.dart';
import 'package:conectenis_app/features/home/models/dashboard_stats.dart';

/// Aggregated stats (record, NTRP, ranking snapshot) — consumed by the
/// Perfil tab since the dashboard home was retired in the redesign.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return ref.watch(dashboardRepositoryProvider).fetchStats();
});
