import 'package:conectenis_app/shared/models/json_parsers.dart';
import 'package:conectenis_app/shared/utils/geo.dart';

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.createdByUserId,
    this.averageRating,
    this.ratingsCount = 0,
    this.distanceKm,
    this.createdAt,
    this.recentReviews = const [],
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int createdByUserId;
  final double? averageRating;
  final int ratingsCount;
  final double? distanceKm;
  final DateTime? createdAt;
  final List<PlaceReview> recentReviews;

  String get subtitle {
    if (distanceKm != null) {
      return '${distanceKm!.toStringAsFixed(1)} km';
    }
    return 'Próximo';
  }

  Place withDistanceFrom(double lat, double lng) {
    return Place(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      createdByUserId: createdByUserId,
      averageRating: averageRating,
      ratingsCount: ratingsCount,
      distanceKm: distanceKmBetween(lat, lng, latitude, longitude),
      createdAt: createdAt,
      recentReviews: recentReviews,
    );
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: parseJsonInt(json['id']),
      name: json['name'] as String? ?? '',
      latitude: parseJsonDouble(json['latitude']),
      longitude: parseJsonDouble(json['longitude']),
      createdByUserId: parseJsonInt(json['created_by_user_id']),
      averageRating: json['average_rating'] == null
          ? null
          : parseJsonDouble(json['average_rating']),
      ratingsCount: parseJsonInt(json['ratings_count']),
      distanceKm: json['distance_km'] == null
          ? null
          : parseJsonDouble(json['distance_km']),
      createdAt: _parseDateTime(json['created_at']),
      recentReviews: (json['recent_reviews'] as List<dynamic>?)
              ?.map((e) => PlaceReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Place && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class PlaceReview {
  const PlaceReview({
    required this.author,
    required this.comment,
    required this.stars,
  });

  final String author;
  final String comment;
  final int stars;

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      author: json['author'] as String? ?? json['user_name'] as String? ?? 'Jogador',
      comment: json['comment'] as String? ?? '',
      stars: parseJsonInt(json['stars']),
    );
  }
}
