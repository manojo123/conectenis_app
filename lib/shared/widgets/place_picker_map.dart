import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
    this.showZoomControls = false,
  });

  final double latitude;
  final double longitude;
  final void Function(double lat, double lng) onLocationChanged;
  final double height;
  final bool showZoomControls;

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS) && Env.googleMapsApiKey.isNotEmpty;

  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers = {
    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
  };

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

  Future<void> _zoomBy(double delta) async {
    final controller = _controller;
    if (controller == null) return;
    final zoom = await controller.getZoomLevel();
    await controller.animateCamera(CameraUpdate.zoomTo((zoom + delta).clamp(3, 20)));
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
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _position, zoom: 15),
              markers: _markers,
              gestureRecognizers: PlacePickerMap._gestureRecognizers,
              onMapCreated: (c) => _controller = c,
              onTap: (pos) {
                setState(() => _position = pos);
                widget.onLocationChanged(pos.latitude, pos.longitude);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: widget.showZoomControls,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
            ),
            if (widget.showZoomControls)
              Positioned(
                right: 12,
                bottom: 12,
                child: Column(
                  children: [
                    _ZoomButton(icon: Icons.add, onPressed: () => _zoomBy(1)),
                    const SizedBox(height: 8),
                    _ZoomButton(icon: Icons.remove, onPressed: () => _zoomBy(-1)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

Future<void> showFullscreenPlacePicker({
  required BuildContext context,
  required double latitude,
  required double longitude,
  required void Function(double lat, double lng) onLocationChanged,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => _FullscreenPlacePickerPage(
        latitude: latitude,
        longitude: longitude,
        onLocationChanged: onLocationChanged,
      ),
    ),
  );
}

class _FullscreenPlacePickerPage extends StatefulWidget {
  const _FullscreenPlacePickerPage({
    required this.latitude,
    required this.longitude,
    required this.onLocationChanged,
  });

  final double latitude;
  final double longitude;
  final void Function(double lat, double lng) onLocationChanged;

  @override
  State<_FullscreenPlacePickerPage> createState() => _FullscreenPlacePickerPageState();
}

class _FullscreenPlacePickerPageState extends State<_FullscreenPlacePickerPage> {
  late double _lat;
  late double _lng;

  @override
  void initState() {
    super.initState();
    _lat = widget.latitude;
    _lng = widget.longitude;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar posição'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Concluir'),
          ),
        ],
      ),
      body: PlacePickerMap(
        latitude: _lat,
        longitude: _lng,
        height: MediaQuery.sizeOf(context).height,
        showZoomControls: true,
        onLocationChanged: (lat, lng) {
          setState(() {
            _lat = lat;
            _lng = lng;
          });
          widget.onLocationChanged(lat, lng);
        },
      ),
    );
  }
}
