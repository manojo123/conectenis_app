import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.ntrpRating = 3.0,
    this.gender,
    this.profession,
    this.addressLine,
    this.city,
    this.state,
    this.country = 'BR',
    this.postalCode,
    this.homeCityId,
    this.playStyle = PlayStyle.both,
    this.avatarUrl,
    this.latitude,
    this.longitude,
    this.profileComplete = false,
    this.roles = const [],
    this.emailVerifiedAt,
    this.unreadNotificationsCount = 0,
  });

  final int id;
  final String name;
  final String email;
  final int? age;
  final double ntrpRating;
  final Gender? gender;
  final String? profession;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final int? homeCityId;
  final PlayStyle playStyle;
  final String? avatarUrl;
  final double? latitude;
  final double? longitude;
  final bool profileComplete;
  final List<String> roles;
  final DateTime? emailVerifiedAt;
  final int unreadNotificationsCount;

  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    int? age,
    double? ntrpRating,
    Gender? gender,
    String? profession,
    String? addressLine,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    int? homeCityId,
    PlayStyle? playStyle,
    String? avatarUrl,
    double? latitude,
    double? longitude,
    bool? profileComplete,
    List<String>? roles,
    DateTime? emailVerifiedAt,
    int? unreadNotificationsCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      ntrpRating: ntrpRating ?? this.ntrpRating,
      gender: gender ?? this.gender,
      profession: profession ?? this.profession,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      homeCityId: homeCityId ?? this.homeCityId,
      playStyle: playStyle ?? this.playStyle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profileComplete: profileComplete ?? this.profileComplete,
      roles: roles ?? this.roles,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      unreadNotificationsCount: unreadNotificationsCount ?? this.unreadNotificationsCount,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: parseJsonInt(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      age: json['age'] == null ? null : parseJsonInt(json['age']),
      ntrpRating: parseJsonDouble(json['ntrp_rating'] ?? 3.0),
      gender: json['gender'] == null ? null : Gender.fromValue(json['gender'] as String?),
      profession: json['profession'] as String?,
      addressLine: json['address_line'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'BR',
      postalCode: json['postal_code'] as String?,
      homeCityId: json['home_city_id'] as int?,
      playStyle: PlayStyle.fromValue(json['play_style'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      profileComplete: json['profile_complete'] as bool? ?? false,
      roles: _parseRoles(json['roles']),
      emailVerifiedAt: _parseDateTime(json['email_verified_at']),
      unreadNotificationsCount: parseJsonInt(json['unread_notifications_count'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'ntrp_rating': ntrpRating,
        'gender': gender?.value,
        'profession': profession,
        'address_line': addressLine,
        'city': city,
        'state': state,
        'country': country,
        'postal_code': postalCode,
        'play_style': playStyle.value,
      };

  factory UserProfile.fromLaravelUser(Map<String, dynamic> json) {
    return UserProfile.fromJson(json);
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
