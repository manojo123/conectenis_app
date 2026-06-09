import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/features/home/data/dashboard_repository.dart';
import 'package:conectenis_app/features/home/models/dashboard_matchmaking.dart';
import 'package:conectenis_app/features/home/models/dashboard_stats.dart';

const kDefaultMatchmakingRadiusKm = 10;

final matchmakingRadiusProvider = StateProvider<int>((ref) {
  return kDefaultMatchmakingRadiusKm;
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return ref.watch(dashboardRepositoryProvider).fetchStats();
});

final dashboardMatchmakingProvider =
    FutureProvider<DashboardMatchmaking>((ref) async {
  final radiusKm = ref.watch(matchmakingRadiusProvider);
  return ref.watch(dashboardRepositoryProvider).fetchMatchmaking(
        radiusKm: radiusKm,
      );
});
