import 'package:conectenis_app/shared/models/json_parsers.dart';

class DashboardMatchmaking {
  const DashboardMatchmaking({
    required this.count,
    required this.radiusKm,
    required this.ntrpRating,
    required this.hasMatches,
  });

  final int count;
  final int radiusKm;
  final double ntrpRating;
  final bool hasMatches;

  factory DashboardMatchmaking.fromJson(Map<String, dynamic> json) {
    return DashboardMatchmaking(
      count: parseJsonInt(json['count']),
      radiusKm: parseJsonInt(json['radius_km']),
      ntrpRating: parseJsonDouble(json['ntrp_rating'], fallback: 3.0),
      hasMatches: json['has_matches'] as bool? ?? parseJsonInt(json['count']) > 0,
    );
  }
}
