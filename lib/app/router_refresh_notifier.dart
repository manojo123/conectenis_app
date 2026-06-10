import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

/// Notifies [GoRouter] to re-run redirect without recreating the router instance.
class RouterRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerRefreshListenableProvider = Provider<RouterRefreshListenable>((ref) {
  final listenable = RouterRefreshListenable();
  ref.onDispose(listenable.dispose);

  ref.listen<AsyncValue<UserProfile?>>(authStateProvider, (previous, next) {
    if (_shouldRefreshRouter(previous, next)) {
      listenable.refresh();
    }
  });

  return listenable;
});

bool _shouldRefreshRouter(
  AsyncValue<UserProfile?>? previous,
  AsyncValue<UserProfile?> next,
) {
  if (previous?.isLoading != next.isLoading) return true;

  final prevUser = previous?.valueOrNull;
  final nextUser = next.valueOrNull;
  if (prevUser == null || nextUser == null) {
    return prevUser != nextUser;
  }

  return prevUser.id != nextUser.id ||
      prevUser.hasAcceptedLegal != nextUser.hasAcceptedLegal ||
      prevUser.profileComplete != nextUser.profileComplete;
}
