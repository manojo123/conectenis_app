import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/place_picker_map.dart';

final mapFilterProvider = StateProvider<MapFilter>((ref) => MapFilter.players);

bool _hasValidCoordinates(double lat, double lng) =>
    lat.abs() > 0.001 || lng.abs() > 0.001;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(MockData.centerLat, MockData.centerLng);
  bool _loading = true;
  String? _error;
  List<Player> _players = [];
  List<Place> _places = [];
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _loading = false;
          _error = 'Permissão de localização negada';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _center = LatLng(pos.latitude, pos.longitude);
      await _loadData();
      await _moveCamera(_center);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _moveCamera(LatLng target, {double zoom = 13}) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final playersRepo = ref.read(playersRepositoryProvider);
      final placesRepo = ref.read(placesRepositoryProvider);
      final results = await Future.wait([
        playersRepo.nearby(lat: _center.latitude, lng: _center.longitude),
        placesRepo.nearby(lat: _center.latitude, lng: _center.longitude),
      ]);
      setState(() {
        _players = results[0] as List<Player>;
        _places = results[1] as List<Place>;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Set<Marker> _buildMarkers(MapFilter filter) {
    if (filter == MapFilter.players) {
      return _players
          .where((p) => _hasValidCoordinates(p.latitude, p.longitude))
          .map(
            (p) => Marker(
              markerId: MarkerId('player_${p.id}'),
              position: LatLng(p.latitude, p.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(title: p.name, snippet: p.skillLevel.label),
              onTap: () => _showPlayerSheet(p),
            ),
          )
          .toSet();
    }
    return _places
        .where((p) => _hasValidCoordinates(p.latitude, p.longitude))
        .map(
          (p) => Marker(
            markerId: MarkerId('place_${p.id}'),
            position: LatLng(p.latitude, p.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: p.name,
              snippet: p.averageRating != null
                  ? '${p.averageRating!.toStringAsFixed(1)} ★ · ${p.subtitle}'
                  : p.subtitle,
            ),
            onTap: () => _openPlace(p),
          ),
        )
        .toSet();
  }

  void _openPlace(Place place) {
    context.push('/places/${place.id}').then((_) => _loadData());
  }

  Future<void> _addPlace() async {
    final created = await context.push<Place>('/places/new');
    if (!mounted) return;
    if (created != null) {
      ref.read(mapFilterProvider.notifier).state = MapFilter.places;
      await _loadData();
      if (_hasValidCoordinates(created.latitude, created.longitude)) {
        await _moveCamera(
          LatLng(created.latitude, created.longitude),
          zoom: 15,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Local "${created.name}" adicionado ao mapa')),
        );
      }
    } else {
      await _loadData();
    }
  }

  void _showPlayerSheet(Player player) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(player.name, style: Theme.of(ctx).textTheme.titleLarge),
            Text('${player.skillLevel.label} · ${player.age ?? '?'} anos'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/players/${player.id}');
              },
              child: const Text('Ver perfil'),
            ),
          ],
        ),
      ),
    );
  }

  bool get _mapsSupported => PlacePickerMap.isSupported;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(mapFilterProvider);
    final markers = _loading ? <Marker>{} : _buildMarkers(filter);
    final placeCount = _places.where((p) => _hasValidCoordinates(p.latitude, p.longitude)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: filter == MapFilter.places
          ? FloatingActionButton.extended(
              onPressed: _addPlace,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Adicionar local'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SegmentedButton<MapFilter>(
              segments: const [
                ButtonSegment(value: MapFilter.players, label: Text('Jogadores'), icon: Icon(Icons.person)),
                ButtonSegment(value: MapFilter.places, label: Text('Lugares'), icon: Icon(Icons.place)),
              ],
              selected: {filter},
              onSelectionChanged: (s) {
                ref.read(mapFilterProvider.notifier).state = s.first;
                setState(() {});
              },
            ),
          ),
          if (filter == MapFilter.places && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$placeCount local(is) no mapa · toque no pin para detalhes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          if (!_mapsSupported && !_loading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: MaterialBanner(
                content: const Text(
                  'Google Maps nativo sem chave. Adicione GOOGLE_MAPS_API_KEY em .env e faça rebuild do app.',
                ),
                actions: [
                  TextButton(onPressed: _loadData, child: const Text('Atualizar')),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const LoadingView(message: 'Carregando mapa...')
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _initLocation)
                    : !_mapsSupported
                        ? _MapListFallback(
                            filter: filter,
                            players: _players,
                            places: _places,
                            onPlayerTap: (p) => context.push('/players/${p.id}'),
                            onPlaceTap: _openPlace,
                          )
                        : GoogleMap(
                            key: ValueKey('map_${filter.name}_${markers.length}'),
                            initialCameraPosition: CameraPosition(target: _center, zoom: 13),
                            markers: markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            onMapCreated: (controller) {
                              _mapController = controller;
                              _moveCamera(_center);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _MapListFallback extends StatelessWidget {
  const _MapListFallback({
    required this.filter,
    required this.players,
    required this.places,
    required this.onPlayerTap,
    required this.onPlaceTap,
  });

  final MapFilter filter;
  final List<Player> players;
  final List<Place> places;
  final void Function(Player) onPlayerTap;
  final void Function(Place) onPlaceTap;

  @override
  Widget build(BuildContext context) {
    if (filter == MapFilter.players) {
      if (players.isEmpty) {
        return const EmptyState(
          icon: Icons.people_outline,
          title: 'Nenhum jogador por perto',
          subtitle: 'Convide amigos para aparecerem no mapa.',
        );
      }
      return ListView.builder(
        itemCount: players.length,
        itemBuilder: (_, i) {
          final p = players[i];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.sports_tennis)),
            title: Text(p.name),
            subtitle: Text('${p.skillLevel.label} · ${p.distanceKm?.toStringAsFixed(1) ?? '?'} km'),
            onTap: () => onPlayerTap(p),
          );
        },
      );
    }
    final visible = places.where((p) => _hasValidCoordinates(p.latitude, p.longitude)).toList();
    if (visible.isEmpty) {
      return const EmptyState(
        icon: Icons.place_outlined,
        title: 'Nenhum local cadastrado',
        subtitle: 'Toque em Adicionar local para cadastrar no mapa.',
      );
    }
    return ListView.builder(
      itemCount: visible.length,
      itemBuilder: (_, i) {
        final p = visible[i];
        return ListTile(
          leading: const Icon(Icons.place, color: AppColors.navy),
          title: Text(p.name),
          subtitle: Text(p.subtitle),
          onTap: () => onPlaceTap(p),
        );
      },
    );
  }
}
