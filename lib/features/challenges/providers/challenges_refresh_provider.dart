import 'package:flutter_riverpod/flutter_riverpod.dart';

final challengesRefreshProvider = StateProvider<int>((ref) => 0);

void bumpChallengesRefresh(WidgetRef ref) {
  ref.read(challengesRefreshProvider.notifier).state++;
}
