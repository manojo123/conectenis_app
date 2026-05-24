import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:conectenis_app/core/config/env.dart';

/// Read-only map preview with a single pin (no pan/zoom controls).
class StaticPlaceMap extends StatelessWidget {
  const StaticPlaceMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 180,
  });

  final double latitude;
  final double longitude;
  final double height;

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS) && Env.googleMapsApiKey.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!isSupported) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Mapa indisponível'),
      );
    }

    final position = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 15),
          markers: {
            Marker(markerId: const MarkerId('place'), position: position),
          },
          zoomGesturesEnabled: false,
          scrollGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomControlsEnabled: false,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          liteModeEnabled: true,
        ),
      ),
    );
  }
}
