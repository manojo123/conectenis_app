import 'package:conectenis_app/shared/models/json_parsers.dart';

class PlayerRatingDimensions {
  const PlayerRatingDimensions({
    this.punctuality,
    this.fairPlay,
    this.communication,
  });

  final double? punctuality;
  final double? fairPlay;
  final double? communication;

  factory PlayerRatingDimensions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerRatingDimensions();
    return PlayerRatingDimensions(
      punctuality: json['punctuality'] == null
          ? null
          : parseJsonDouble(json['punctuality']),
      fairPlay: json['fair_play'] == null ? null : parseJsonDouble(json['fair_play']),
      communication: json['communication'] == null
          ? null
          : parseJsonDouble(json['communication']),
    );
  }
}

class PlaceRatingDimensions {
  const PlaceRatingDimensions({
    this.courtQuality,
    this.infrastructure,
  });

  final double? courtQuality;
  final double? infrastructure;

  factory PlaceRatingDimensions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlaceRatingDimensions();
    return PlaceRatingDimensions(
      courtQuality: json['court_quality'] == null
          ? null
          : parseJsonDouble(json['court_quality']),
      infrastructure: json['infrastructure'] == null
          ? null
          : parseJsonDouble(json['infrastructure']),
    );
  }
}
