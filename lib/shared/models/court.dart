class Court {
  const Court({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.city,
    this.state,
    this.distanceKm,
  });

  final int id;
  final String name;
  final String address;
  final String? phone;
  final String? city;
  final String? state;
  final double latitude;
  final double longitude;
  final double? distanceKm;

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}
