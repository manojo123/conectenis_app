import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/shared/widgets/place_picker_map.dart';

class CreatePlaceScreen extends ConsumerStatefulWidget {
  const CreatePlaceScreen({super.key});

  @override
  ConsumerState<CreatePlaceScreen> createState() => _CreatePlaceScreenState();
}

class _CreatePlaceScreenState extends ConsumerState<CreatePlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  double _lat = MockData.centerLat;
  double _lng = MockData.centerLng;
  bool _loadingGps = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadGps();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadGps() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _loadingGps = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _loadingGps = false;
      });
    } catch (_) {
      setState(() => _loadingGps = false);
    }
  }

  void _onMapLocationChanged(double lat, double lng) {
    setState(() {
      _lat = lat;
      _lng = lng;
    });
  }

  Future<void> _openFullscreenMap() async {
    await showFullscreenPlacePicker(
      context: context,
      latitude: _lat,
      longitude: _lng,
      onLocationChanged: _onMapLocationChanged,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final place = await ref.read(placesRepositoryProvider).create(
            name: _nameController.text.trim(),
            latitude: _lat,
            longitude: _lng,
          );
      if (!mounted) return;
      context.pop(place);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo local')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do local',
                hintText: 'Ex.: Clube Tênis Centro',
              ),
              validator: (v) =>
                  v == null || v.trim().length < 2 ? 'Mínimo 2 caracteres' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Posição no mapa',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Toque no mapa ou arraste o pin azul para ajustar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (_loadingGps)
              const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()))
            else
              PlacePickerMap(
                latitude: _lat,
                longitude: _lng,
                onLocationChanged: _onMapLocationChanged,
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loadingGps ? null : _openFullscreenMap,
              icon: const Icon(Icons.fullscreen),
              label: const Text('Abrir mapa em tela cheia'),
            ),
            const SizedBox(height: 8),
            Text('Lat: ${_lat.toStringAsFixed(5)}, Lng: ${_lng.toStringAsFixed(5)}'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loadingGps ? null : _loadGps,
              icon: const Icon(Icons.my_location),
              label: const Text('Centralizar na minha localização'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar local'),
            ),
          ],
        ),
      ),
    );
  }
}
