import 'package:flutter/material.dart';
import 'package:conectenis_app/shared/models/enums.dart';

class ChallengesWallFilters {
  const ChallengesWallFilters({
    this.statuses = const {},
    this.scheduledFrom,
    this.scheduledTo,
    this.includeHistory = false,
  });

  final Set<ChallengeStatus> statuses;
  final DateTime? scheduledFrom;
  final DateTime? scheduledTo;
  final bool includeHistory;

  bool get hasActiveFilters =>
      statuses.isNotEmpty || scheduledFrom != null || scheduledTo != null;

  ChallengesWallFilters copyWith({
    Set<ChallengeStatus>? statuses,
    DateTime? scheduledFrom,
    DateTime? scheduledTo,
    bool? includeHistory,
    bool clearDates = false,
    bool clearStatuses = false,
  }) {
    return ChallengesWallFilters(
      statuses: clearStatuses ? {} : (statuses ?? this.statuses),
      scheduledFrom: clearDates ? null : (scheduledFrom ?? this.scheduledFrom),
      scheduledTo: clearDates ? null : (scheduledTo ?? this.scheduledTo),
      includeHistory: includeHistory ?? this.includeHistory,
    );
  }
}

class ChallengeWallFilterBar extends StatelessWidget {
  const ChallengeWallFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
    this.showHistoryToggle = true,
  });

  final ChallengesWallFilters filters;
  final ValueChanged<ChallengesWallFilters> onChanged;
  final bool showHistoryToggle;

  static const _filterableStatuses = [
    ChallengeStatus.pendingAcceptance,
    ChallengeStatus.pendingCandidates,
    ChallengeStatus.candidatesAwaitingAccept,
    ChallengeStatus.accepted,
    ChallengeStatus.pendingScore,
    ChallengeStatus.pendingResultApproval,
    ChallengeStatus.completed,
    ChallengeStatus.cancelled,
    ChallengeStatus.declined,
    ChallengeStatus.expired,
  ];

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: filters.scheduledFrom != null && filters.scheduledTo != null
          ? DateTimeRange(start: filters.scheduledFrom!, end: filters.scheduledTo!)
          : null,
      locale: const Locale('pt', 'BR'),
    );
    if (range == null) return;
    onChanged(filters.copyWith(
      scheduledFrom: range.start,
      scheduledTo: range.end,
    ));
  }

  void _toggleStatus(ChallengeStatus status) {
    final next = Set<ChallengeStatus>.from(filters.statuses);
    if (next.contains(status)) {
      next.remove(status);
    } else {
      next.add(status);
    }
    onChanged(filters.copyWith(statuses: next));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Data'),
                          selected: filters.scheduledFrom != null,
                          onSelected: (_) => _pickDateRange(context),
                        ),
                        const SizedBox(width: 6),
                        ..._filterableStatuses.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(s.label, style: const TextStyle(fontSize: 12)),
                              selected: filters.statuses.contains(s),
                              onSelected: (_) => _toggleStatus(s),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filters.hasActiveFilters)
                  IconButton(
                    tooltip: 'Limpar filtros',
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => onChanged(
                      ChallengesWallFilters(includeHistory: filters.includeHistory),
                    ),
                  ),
              ],
            ),
            if (showHistoryToggle)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Incluir histórico na busca', style: TextStyle(fontSize: 13)),
                value: filters.includeHistory,
                onChanged: (v) => onChanged(filters.copyWith(includeHistory: v)),
              ),
          ],
        ),
      ),
    );
  }
}
