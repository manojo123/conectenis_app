import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';
import 'package:conectenis_app/shared/utils/date_of_birth.dart';

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.dateOfBirth,
    this.ntrpRating = 3.0,
    this.gender,
    this.profession,
    this.city,
    this.state,
    this.playStyle = PlayStyle.both,
    this.avatarUrl,
    this.distanceKm,
    this.matchesPlayed,
    this.challengesWon,
    this.averageRating,
    this.reviewsCount,
    this.recentReviews = const [],
  });

  final int id;
  final String name;
  final DateTime? dateOfBirth;
  final double ntrpRating;
  final Gender? gender;
  final String? profession;
  final String? city;
  final String? state;
  final PlayStyle playStyle;
  final String? avatarUrl;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final int? matchesPlayed;
  final int? challengesWon;
  final double? averageRating;
  final int? reviewsCount;
  final List<PlayerReview> recentReviews;

  int? get age => ageFromDateOfBirth(dateOfBirth);

  String get locationLabel {
    if (city != null && state != null) return '$city, $state';
    return city ?? state ?? '';
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    final dob = parseDateOfBirth(json['date_of_birth']) ??
        _dateOfBirthFromAge(json['age']);

    return Player(
      id: parseJsonInt(json['id']),
      name: json['name'] as String? ?? '',
      dateOfBirth: dob,
      ntrpRating: parseJsonDouble(json['ntrp_rating'] ?? json['skill_level']),
      gender: json['gender'] == null ? null : Gender.fromValue(json['gender'] as String?),
      profession: json['profession'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      playStyle: PlayStyle.fromValue(json['play_style'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      latitude: parseJsonDouble(json['latitude']),
      longitude: parseJsonDouble(json['longitude']),
      distanceKm: json['distance_km'] == null
          ? null
          : parseJsonDouble(json['distance_km']),
      matchesPlayed: json['matches_played'] as int?,
      challengesWon: json['challenges_won'] as int?,
      averageRating: json['average_rating'] == null
          ? null
          : parseJsonDouble(json['average_rating']),
      reviewsCount: json['reviews_count'] as int?,
      recentReviews: (json['recent_reviews'] as List<dynamic>?)
              ?.map((e) => PlayerReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  static DateTime? _dateOfBirthFromAge(dynamic ageValue) {
    if (ageValue == null) return null;
    final age = parseJsonInt(ageValue);
    if (age <= 0) return null;
    return DateTime(DateTime.now().year - age, 1, 1);
  }
}

class PlayerReview {
  const PlayerReview({
    required this.author,
    required this.comment,
    required this.stars,
  });

  final String author;
  final String comment;
  final int stars;

  factory PlayerReview.fromJson(Map<String, dynamic> json) {
    return PlayerReview(
      author: json['author'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      stars: parseJsonInt(json['stars']),
    );
  }
}
