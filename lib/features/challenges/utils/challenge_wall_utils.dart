import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';

/// Historical statuses hidden by default under "Ver Histórico".
const challengeHistoryStatuses = {
  ChallengeStatus.cancelled,
  ChallengeStatus.completed,
  ChallengeStatus.declined,
  ChallengeStatus.expired,
};

bool isChallengeHistory(Challenge challenge) => challengeHistoryStatuses.contains(challenge.status);

int challengePriorityTier(ChallengeStatus status) {
  return switch (status) {
    ChallengeStatus.pendingAcceptance ||
    ChallengeStatus.pendingCandidates ||
    ChallengeStatus.candidatesAwaitingAccept =>
      0,
    ChallengeStatus.accepted => 1,
    ChallengeStatus.pendingScore || ChallengeStatus.pendingResultApproval => 2,
    _ => 3,
  };
}

/// Actionable-first sort: tier ASC, then scheduled_start ASC (soonest first).
List<Challenge> sortChallengesByPriority(List<Challenge> items) {
  final copy = List<Challenge>.from(items);
  copy.sort((a, b) {
    final tierCompare =
        challengePriorityTier(a.status).compareTo(challengePriorityTier(b.status));
    if (tierCompare != 0) return tierCompare;
    return a.scheduledStart.compareTo(b.scheduledStart);
  });
  return copy;
}

({List<Challenge> actionable, List<Challenge> history}) partitionChallenges(
  List<Challenge> items, {
  bool includeHistory = false,
}) {
  final actionable = <Challenge>[];
  final history = <Challenge>[];
  for (final c in items) {
    if (isChallengeHistory(c)) {
      history.add(c);
    } else {
      actionable.add(c);
    }
  }
  return (
    actionable: sortChallengesByPriority(actionable),
    history: includeHistory ? sortChallengesByPriority(history) : history,
  );
}

List<Challenge> filterChallengesByStatus(
  List<Challenge> items,
  Set<ChallengeStatus>? statuses,
) {
  if (statuses == null || statuses.isEmpty) return items;
  return items.where((c) => statuses.contains(c.status)).toList();
}

List<Challenge> filterChallengesByDateRange(
  List<Challenge> items, {
  DateTime? from,
  DateTime? to,
}) {
  return items.where((c) {
    if (from != null && c.scheduledStart.isBefore(from)) return false;
    if (to != null) {
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
      if (c.scheduledStart.isAfter(endOfDay)) return false;
    }
    return true;
  }).toList();
}
