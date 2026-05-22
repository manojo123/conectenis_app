import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.age,
    this.skillLevel = SkillLevel.intermediate,
    this.playStyle = PlayStyle.both,
    this.avatarUrl,
    this.distanceKm,
  });

  final int id;
  final String name;
  final int? age;
  final SkillLevel skillLevel;
  final PlayStyle playStyle;
  final String? avatarUrl;
  final double latitude;
  final double longitude;
  final double? distanceKm;

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: parseJsonInt(json['id']),
      name: json['name'] as String? ?? '',
      age: json['age'] == null ? null : parseJsonInt(json['age']),
      skillLevel: SkillLevel.fromValue(json['skill_level'] as String?),
      playStyle: PlayStyle.fromValue(json['play_style'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      latitude: parseJsonDouble(json['latitude']),
      longitude: parseJsonDouble(json['longitude']),
      distanceKm: json['distance_km'] == null
          ? null
          : parseJsonDouble(json['distance_km']),
    );
  }
}
