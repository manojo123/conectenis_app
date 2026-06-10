import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/features/home/providers/dashboard_providers.dart';
import 'package:conectenis_app/shared/models/enums.dart';

class PublicChallengeFilters {
  const PublicChallengeFilters({
    this.radiusKm = kDefaultMatchmakingRadiusKm,
    this.format,
    this.minNtrp,
    this.maxNtrp,
    this.scheduledFrom,
    this.scheduledTo,
    this.search = '',
  });

  final int radiusKm;
  final ChallengeFormat? format;
  final double? minNtrp;
  final double? maxNtrp;
  final DateTime? scheduledFrom;
  final DateTime? scheduledTo;
  final String search;

  PublicChallengeFilters copyWith({
    int? radiusKm,
    ChallengeFormat? format,
    bool clearFormat = false,
    double? minNtrp,
    bool clearMinNtrp = false,
    double? maxNtrp,
    bool clearMaxNtrp = false,
    DateTime? scheduledFrom,
    bool clearScheduledFrom = false,
    DateTime? scheduledTo,
    bool clearScheduledTo = false,
    String? search,
  }) {
    return PublicChallengeFilters(
      radiusKm: radiusKm ?? this.radiusKm,
      format: clearFormat ? null : (format ?? this.format),
      minNtrp: clearMinNtrp ? null : (minNtrp ?? this.minNtrp),
      maxNtrp: clearMaxNtrp ? null : (maxNtrp ?? this.maxNtrp),
      scheduledFrom: clearScheduledFrom ? null : (scheduledFrom ?? this.scheduledFrom),
      scheduledTo: clearScheduledTo ? null : (scheduledTo ?? this.scheduledTo),
      search: search ?? this.search,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'radius_km': radiusKm,
      if (format != null) 'format': format!.value,
      if (minNtrp != null) 'min_ntrp': minNtrp,
      if (maxNtrp != null) 'max_ntrp': maxNtrp,
      if (scheduledFrom != null) 'scheduled_from': scheduledFrom!.toIso8601String(),
      if (scheduledTo != null) 'scheduled_to': scheduledTo!.toIso8601String(),
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
  }
}

final publicChallengesFilterProvider =
    StateProvider<PublicChallengeFilters>((ref) {
  return const PublicChallengeFilters();
});
