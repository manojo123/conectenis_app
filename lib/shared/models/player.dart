import 'package:conectenis_app/shared/models/enums.dart';

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
      id: json['id'] as int,
      name: json['name'] as String,
      age: json['age'] as int?,
      skillLevel: SkillLevel.fromValue(json['skill_level'] as String?),
      playStyle: PlayStyle.fromValue(json['play_style'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}
