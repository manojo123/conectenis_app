import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceSelectorField extends ConsumerStatefulWidget {
  const PlaceSelectorField({
    super.key,
    required this.selectedPlace,
    required this.onChanged,
    this.label = 'Local',
    this.allowCreate = true,
  });

  final Place? selectedPlace;
  final ValueChanged<Place?> onChanged;
  final String label;
  final bool allowCreate;

  @override
  ConsumerState<PlaceSelectorField> createState() => _PlaceSelectorFieldState();
}

class _PlaceSelectorFieldState extends ConsumerState<PlaceSelectorField> {
  List<Place> _places = [];
  bool _loading = true;
  double _userLat = MockData.centerLat;
  double _userLng = MockData.centerLng;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  List<Place> _dedupePlaces(List<Place> list) {
    final seen = <int>{};
    final result = <Place>[];
    for (final place in list) {
      if (seen.add(place.id)) result.add(place);
    }
    return result;
  }

  Place? _resolveSelected() {
    final selected = widget.selectedPlace;
    if (selected == null) return null;
    for (final place in _places) {
      if (place.id == selected.id) return place;
    }
    return selected;
  }

  Future<void> _loadPlaces() async {
    setState(() => _loading = true);
    try {
      double lat = MockData.centerLat;
      double lng = MockData.centerLng;
      try {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}
      _userLat = lat;
      _userLng = lng;
      final list = await ref.read(placesRepositoryProvider).nearby(lat: lat, lng: lng);
      if (!mounted) return;
      setState(() {
        _places = _dedupePlaces(list);
        _loading = false;
      });
      if (widget.selectedPlace == null && _places.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onChanged(_places.first);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addNewPlace() async {
    final place = await context.push<Place>('/places/new');
    if (place == null || !mounted) return;
    await _loadPlaces();
    final withDistance = place.withDistanceFrom(_userLat, _userLng);
    final match = _places.where((p) => p.id == place.id).toList();
    final resolved = match.isNotEmpty ? match.first : withDistance;
    if (match.isEmpty) {
      setState(() => _places = _dedupePlaces([withDistance, ..._places]));
    }
    widget.onChanged(resolved);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_places.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nenhum local por perto.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (widget.allowCreate) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addNewPlace,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Cadastrar local'),
            ),
          ],
        ],
      );
    }

    final selected = _resolveSelected();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey('place-${selected?.id ?? 'none'}-${_places.length}'),
          initialValue: selected?.id,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
          ),
          items: _places
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.name} (${p.subtitle})'),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            widget.onChanged(_places.firstWhere((p) => p.id == id));
          },
        ),
        if (widget.allowCreate) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addNewPlace,
            icon: const Icon(Icons.add),
            label: const Text('Novo local'),
          ),
        ],
      ],
    );
  }
}
