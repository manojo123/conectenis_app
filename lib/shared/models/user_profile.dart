import 'package:conectenis_app/shared/utils/gravatar.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';
import 'package:conectenis_app/shared/utils/date_of_birth.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.dateOfBirth,
    this.ntrpRating = 3.0,
    this.gender,
    this.profession,
    this.addressLine,
    this.city,
    this.state,
    this.country = 'BR',
    this.postalCode,
    this.homeCityId,
    this.neighborhood,
    this.addressNumber,
    this.addressComplement,
    this.playStyle = PlayStyle.both,
    this.avatarUrl,
    this.hasCustomAvatar = false,
    this.latitude,
    this.longitude,
    this.profileComplete = false,
    this.roles = const [],
    this.emailVerifiedAt,
    this.termsAcceptedAt,
    this.privacyAcceptedAt,
    this.legalVersion,
    this.unreadNotificationsCount = 0,
  });

  final int id;
  final String name;
  final String email;
  final DateTime? dateOfBirth;
  final double ntrpRating;
  final Gender? gender;
  final String? profession;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final int? homeCityId;
  final String? neighborhood;
  final String? addressNumber;
  final String? addressComplement;
  final PlayStyle playStyle;
  final String? avatarUrl;
  final bool hasCustomAvatar;
  final double? latitude;
  final double? longitude;
  final bool profileComplete;
  final List<String> roles;
  final DateTime? emailVerifiedAt;
  final DateTime? termsAcceptedAt;
  final DateTime? privacyAcceptedAt;
  final String? legalVersion;
  final int unreadNotificationsCount;

  int? get age => ageFromDateOfBirth(dateOfBirth);

  bool get hasAcceptedLegal =>
      termsAcceptedAt != null && privacyAcceptedAt != null;

  /// Display URL: custom upload or Gravatar fallback.
  String get displayAvatarUrl => resolveAvatarUrl(
        avatarUrl: avatarUrl,
        email: email,
        hasCustomAvatar: hasCustomAvatar,
      );

  bool get isAdmin => roles.any((r) => r.toLowerCase() == 'admin');

  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    DateTime? dateOfBirth,
    double? ntrpRating,
    Gender? gender,
    String? profession,
    String? addressLine,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    int? homeCityId,
    String? neighborhood,
    String? addressNumber,
    String? addressComplement,
    PlayStyle? playStyle,
    String? avatarUrl,
    bool? hasCustomAvatar,
    double? latitude,
    double? longitude,
    bool? profileComplete,
    List<String>? roles,
    DateTime? emailVerifiedAt,
    DateTime? termsAcceptedAt,
    DateTime? privacyAcceptedAt,
    String? legalVersion,
    int? unreadNotificationsCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      ntrpRating: ntrpRating ?? this.ntrpRating,
      gender: gender ?? this.gender,
      profession: profession ?? this.profession,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      homeCityId: homeCityId ?? this.homeCityId,
      neighborhood: neighborhood ?? this.neighborhood,
      addressNumber: addressNumber ?? this.addressNumber,
      addressComplement: addressComplement ?? this.addressComplement,
      playStyle: playStyle ?? this.playStyle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasCustomAvatar: hasCustomAvatar ?? this.hasCustomAvatar,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profileComplete: profileComplete ?? this.profileComplete,
      roles: roles ?? this.roles,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      privacyAcceptedAt: privacyAcceptedAt ?? this.privacyAcceptedAt,
      legalVersion: legalVersion ?? this.legalVersion,
      unreadNotificationsCount: unreadNotificationsCount ?? this.unreadNotificationsCount,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final dob = parseDateOfBirth(json['date_of_birth']) ??
        _dateOfBirthFromAge(json['age']);

    return UserProfile(
      id: parseJsonInt(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: dob,
      ntrpRating: parseJsonDouble(json['ntrp_rating'] ?? 3.0),
      gender: json['gender'] == null ? null : Gender.fromValue(json['gender'] as String?),
      profession: json['profession'] as String?,
      addressLine: json['address_line'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'BR',
      postalCode: json['postal_code'] as String?,
      homeCityId: json['home_city_id'] as int?,
      neighborhood: json['neighborhood'] as String?,
      addressNumber: json['address_number'] as String?,
      addressComplement: json['address_complement'] as String?,
      playStyle: PlayStyle.fromValue(json['play_style'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      hasCustomAvatar: json['has_custom_avatar'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      profileComplete: json['profile_complete'] as bool? ?? false,
      roles: _parseRoles(json['roles']),
      emailVerifiedAt: _parseDateTime(json['email_verified_at']),
      termsAcceptedAt: _parseDateTime(json['terms_accepted_at']),
      privacyAcceptedAt: _parseDateTime(json['privacy_accepted_at']),
      legalVersion: json['legal_version'] as String?,
      unreadNotificationsCount: parseJsonInt(json['unread_notifications_count'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
        'ntrp_rating': ntrpRating,
        'gender': gender?.value,
        'profession': profession,
        'address_line': addressLine,
        'city': city,
        'state': state,
        'country': country,
        'postal_code': postalCode,
        if (neighborhood != null && neighborhood!.isNotEmpty) 'neighborhood': neighborhood,
        if (addressNumber != null && addressNumber!.isNotEmpty) 'address_number': addressNumber,
        if (addressComplement != null && addressComplement!.isNotEmpty) 'address_complement': addressComplement,
        'play_style': playStyle.value,
        if (avatarUrl != null && avatarUrl!.isNotEmpty) 'avatar_url': avatarUrl,
        'profile_complete': profileComplete,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'roles': roles,
      };

  factory UserProfile.fromLaravelUser(Map<String, dynamic> json) {
    return UserProfile.fromJson(json);
  }

  static DateTime? _dateOfBirthFromAge(dynamic ageValue) {
    if (ageValue == null) return null;
    final age = parseJsonInt(ageValue);
    if (age <= 0) return null;
    return DateTime(DateTime.now().year - age, 1, 1);
  }

  static List<String> _parseRoles(dynamic value) {
    if (value is List) {
      return value.map((e) {
        if (e is Map) return e['name']?.toString() ?? '';
        return e.toString();
      }).where((r) => r.isNotEmpty).toList();
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
