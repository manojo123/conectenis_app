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
