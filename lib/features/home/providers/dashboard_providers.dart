import 'dart:async';

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
    AsyncNotifierProvider<DashboardMatchmakingNotifier, DashboardMatchmaking>(
  DashboardMatchmakingNotifier.new,
);

class DashboardMatchmakingNotifier extends AsyncNotifier<DashboardMatchmaking> {
  @override
  Future<DashboardMatchmaking> build() async {
    ref.listen<int>(matchmakingRadiusProvider, (previous, next) {
      if (previous != next) {
        unawaited(_reload(next));
      }
    });
    final radiusKm = ref.read(matchmakingRadiusProvider);
    return ref.read(dashboardRepositoryProvider).fetchMatchmaking(
          radiusKm: radiusKm,
        );
  }

  Future<void> refresh() async {
    await _reload(ref.read(matchmakingRadiusProvider));
  }

  Future<void> _reload(int radiusKm) async {
    final previous = state.valueOrNull;
    try {
      final data = await ref.read(dashboardRepositoryProvider).fetchMatchmaking(
            radiusKm: radiusKm,
          );
      state = AsyncData(data);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
    }
  }
}
