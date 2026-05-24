import 'package:geocoding/geocoding.dart';

Future<String?> reverseGeocodeAddress(double latitude, double longitude) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;
    final parts = <String>[
      if (p.street != null && p.street!.isNotEmpty) p.street!,
      if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
      if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  } catch (_) {
    return null;
  }
}
