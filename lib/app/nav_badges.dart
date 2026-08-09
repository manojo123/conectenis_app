import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';

/// Bumped whenever conversations are read/changed so the messages badge
/// refreshes (same counter-as-event-bus pattern as [challengesRefreshProvider]).
final conversationsRefreshProvider = StateProvider<int>((_) => 0);

void bumpConversationsRefresh(WidgetRef ref) {
  ref.read(conversationsRefreshProvider.notifier).state++;
}

/// Direct challenges waiting for the user's answer - Desafios tab badge.
final pendingChallengesCountProvider = FutureProvider<int>((ref) async {
  ref.watch(challengesRefreshProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;
  try {
    final received =
        await ref.watch(challengesRepositoryProvider).list(ChallengeListRole.received);
    return received
        .where((c) => c.status == ChallengeStatus.pendingAcceptance)
        .length;
  } catch (_) {
    return 0;
  }
});

/// Sum of per-conversation unread counts - Mensagens tab badge.
/// Depends on the backend `unread_count` field (0 until it ships).
final unreadMessagesCountProvider = FutureProvider<int>((ref) async {
  ref.watch(conversationsRefreshProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;
  try {
    final conversations = await ref.watch(chatRepositoryProvider).conversations();
    return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
  } catch (_) {
    return 0;
  }
});

/// Unread notifications - comes with the authenticated user payload.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.unreadNotificationsCount ?? 0;
});
