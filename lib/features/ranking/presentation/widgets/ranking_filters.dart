import 'package:conectenis_app/shared/models/enums.dart';

/// Unified-by-default ranking filters: the main view shows everyone in the
/// user's city on one leaderboard - format/NTRP only narrow the view when
/// explicitly picked in the filter sheet.
class RankingFilters {
  const RankingFilters({
    this.geo = RankingGeoScope.city,
    this.gender = RankingGenderFilter.all,
    this.format,
    this.ntrpMin,
    this.ntrpMax,
    this.cityId,
    this.cityLabel,
  });

  final RankingGeoScope geo;
  final RankingGenderFilter gender;
  final ChallengeFormat? format;

  /// NTRP goes 0.0-5.0. Both null means unrestricted (both must be set
  /// together - a range, not a single level).
  final double? ntrpMin;
  final double? ntrpMax;
  final int? cityId;
  final String? cityLabel;

  bool get hasActiveFilters =>
      geo != RankingGeoScope.city ||
      gender != RankingGenderFilter.all ||
      format != null ||
      ntrpMin != null ||
      cityId != null;

  RankingFilters copyWith({
    RankingGeoScope? geo,
    RankingGenderFilter? gender,
    ChallengeFormat? format,
    double? ntrpMin,
    double? ntrpMax,
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
      ntrpMin: clearNtrp ? null : (ntrpMin ?? this.ntrpMin),
      ntrpMax: clearNtrp ? null : (ntrpMax ?? this.ntrpMax),
      cityId: clearCity ? null : (cityId ?? this.cityId),
      cityLabel: clearCity ? null : (cityLabel ?? this.cityLabel),
    );
  }
}
