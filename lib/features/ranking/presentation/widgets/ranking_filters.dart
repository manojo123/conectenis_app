import 'package:conectenis_app/shared/models/enums.dart';

/// Unified-by-default ranking filters: the main view shows everyone in the
/// user's city on one leaderboard - format/NTRP only narrow the view when
/// explicitly picked in the filter sheet.
class RankingFilters {
  const RankingFilters({
    this.geo = RankingGeoScope.city,
    this.gender = RankingGenderFilter.all,
    this.format,
    this.ntrpLevel,
    this.cityId,
    this.cityLabel,
  });

  final RankingGeoScope geo;
  final RankingGenderFilter gender;
  final ChallengeFormat? format;
  final double? ntrpLevel;
  final int? cityId;
  final String? cityLabel;

  bool get hasActiveFilters =>
      geo != RankingGeoScope.city ||
      gender != RankingGenderFilter.all ||
      format != null ||
      ntrpLevel != null ||
      cityId != null;

  RankingFilters copyWith({
    RankingGeoScope? geo,
    RankingGenderFilter? gender,
    ChallengeFormat? format,
    double? ntrpLevel,
    int? cityId,
    String? cityLabel,
    bool clearFormat = false,
    bool clearNtrp = false,
    bool clearCity = false,
  }) {
    return RankingFilters(
      geo: geo ?? this.geo,
      gender: gender ?? this.gender,
      format: clearFormat ? null : (format ?? this.format),
      ntrpLevel: clearNtrp ? null : (ntrpLevel ?? this.ntrpLevel),
      cityId: clearCity ? null : (cityId ?? this.cityId),
      cityLabel: clearCity ? null : (cityLabel ?? this.cityLabel),
    );
  }
}
