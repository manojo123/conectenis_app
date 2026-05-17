import 'package:conectenis_app/shared/models/enums.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.skillLevel = SkillLevel.intermediate,
    this.playStyle = PlayStyle.both,
    this.avatarUrl,
    this.latitude,
    this.longitude,
    this.profileComplete = false,
    this.roles = const [],
    this.emailVerifiedAt,
  });

  final int id;
  final String name;
  final String email;
  final int? age;
  final SkillLevel skillLevel;
  final PlayStyle playStyle;
  final String? avatarUrl;
  final double? latitude;
  final double? longitude;
  final bool profileComplete;
  final List<String> roles;
  final DateTime? emailVerifiedAt;

  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    int? age,
    SkillLevel? skillLevel,
    PlayStyle? playStyle,
    String? avatarUrl,
    double? latitude,
    double? longitude,
    bool? profileComplete,
    List<String>? roles,
    DateTime? emailVerifiedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      skillLevel: skillLevel ?? this.skillLevel,
      playStyle: playStyle ?? this.playStyle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profileComplete: profileComplete ?? this.profileComplete,
      roles: roles ?? this.roles,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      age: json['age'] as int?,
      skillLevel: SkillLevel.fromValue(json['skill_level'] as String?),
      playStyle: PlayStyle.fromValue(json['play_style'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      profileComplete: json['profile_complete'] as bool? ?? false,
      roles: _parseRoles(json['roles']),
      emailVerifiedAt: _parseDateTime(json['email_verified_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'age': age,
        'skill_level': skillLevel.value,
        'play_style': playStyle.value,
        'avatar_url': avatarUrl,
        'latitude': latitude,
        'longitude': longitude,
        'profile_complete': profileComplete,
        'roles': roles,
        'email_verified_at': emailVerifiedAt?.toIso8601String(),
      };

  factory UserProfile.fromLaravelUser(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileComplete: false,
      roles: _parseRoles(json['roles']),
      emailVerifiedAt: _parseDateTime(json['email_verified_at']),
    );
  }

  static List<String> _parseRoles(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
