import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:conectenis_app/core/config/env.dart';

/// Interactive map to pick latitude/longitude by tapping or dragging the pin.
class PlacePickerMap extends StatefulWidget {
  const PlacePickerMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onLocationChanged,
    this.height = 220,
  });

  final double latitude;
  final double longitude;
  final void Function(double lat, double lng) onLocationChanged;
  final double height;

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS) && Env.googleMapsApiKey.isNotEmpty;

  @override
  State<PlacePickerMap> createState() => _PlacePickerMapState();
}

class _PlacePickerMapState extends State<PlacePickerMap> {
  GoogleMapController? _controller;
  late LatLng _position;

  @override
  void initState() {
    super.initState();
    _position = LatLng(widget.latitude, widget.longitude);
  }

  @override
  void didUpdateWidget(PlacePickerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude || oldWidget.longitude != widget.longitude) {
      _position = LatLng(widget.latitude, widget.longitude);
      _controller?.animateCamera(CameraUpdate.newLatLng(_position));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('picker'),
          position: _position,
          draggable: true,
          onDragEnd: (pos) {
            setState(() => _position = pos);
            widget.onLocationChanged(pos.latitude, pos.longitude);
          },
        ),
      };

  @override
  Widget build(BuildContext context) {
    if (!PlacePickerMap.isSupported) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Mapa indisponível. Use o botão de localização ou configure GOOGLE_MAPS_API_KEY.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _position, zoom: 15),
          markers: _markers,
          onMapCreated: (c) => _controller = c,
          onTap: (pos) {
            setState(() => _position = pos);
            widget.onLocationChanged(pos.latitude, pos.longitude);
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}
