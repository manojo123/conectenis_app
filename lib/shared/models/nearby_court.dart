import 'package:conectenis_app/shared/models/json_parsers.dart';

/// Court from hybrid nearby API (app DB and/or Google Places).
class NearbyCourt {
  const NearbyCourt({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.distanceKm,
    this.placeId,
    this.googlePlaceId,
    this.source,
  });

  final String name;
  final String? address;
  final double? distanceKm;
  final double latitude;
  final double longitude;
  final int? placeId;
  final String? googlePlaceId;
  final String? source;

  String get subtitle {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (distanceKm != null) parts.add('${distanceKm!.toStringAsFixed(1)} km');
    return parts.isEmpty ? 'Próximo' : parts.join(' · ');
  }

  bool get isAppPlace => placeId != null;
  bool get isGooglePlace => googlePlaceId != null && googlePlaceId!.isNotEmpty;

  factory NearbyCourt.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final googleId = json['google_place_id'] as String?;
    return NearbyCourt(
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      distanceKm: json['distance_km'] == null
          ? null
          : parseJsonDouble(json['distance_km']),
      latitude: parseJsonDouble(json['latitude']),
      longitude: parseJsonDouble(json['longitude']),
      placeId: id == null ? null : parseJsonInt(id),
      googlePlaceId: googleId,
      source: json['source'] as String?,
    );
  }
}
