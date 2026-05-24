import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/place_picker_map.dart';

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
  bool _showPlayers = true;
  bool _showPlaces = true;

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

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_showPlayers) {
      markers.addAll(
        _players
            .where((p) => _hasValidCoordinates(p.latitude, p.longitude))
            .map(
              (p) => Marker(
                markerId: MarkerId('player_${p.id}'),
                position: LatLng(p.latitude, p.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: InfoWindow(
                  title: p.name,
                  snippet: 'NTRP ${p.ntrpRating.toStringAsFixed(1)}',
                ),
                onTap: () => _showPlayerSheet(p),
              ),
            ),
      );
    }
    if (_showPlaces) {
      markers.addAll(
        _places
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
            ),
      );
    }
    return markers;
  }

  void _openPlace(Place place) {
    context.push('/places/${place.id}').then((_) => _loadData());
  }

  Future<void> _addPlace() async {
    final created = await context.push<Place>('/places/new');
    if (!mounted) return;
    if (created != null) {
      setState(() => _showPlaces = true);
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

  Future<void> _messagePlayer(Player player) async {
    try {
      final conv = await ref.read(chatRepositoryProvider).start(player.id, player.name);
      if (!mounted) return;
      openChatThread(
        context,
        Conversation(
          id: conv.id,
          otherUserId: conv.otherUserId,
          otherUserName: conv.otherUserName,
          otherAvatarUrl: player.avatarUrl ?? conv.otherAvatarUrl,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
            Text('NTRP ${player.ntrpRating.toStringAsFixed(1)} · ${player.age ?? '?'} anos'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/players/${player.id}');
              },
              child: const Text('Ver perfil'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _messagePlayer(player);
              },
              child: const Text('Mensagem'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/challenges/new/direct?playerId=${player.id}');
              },
              child: const Text('Desafiar'),
            ),
          ],
        ),
      ),
    );
  }

  bool get _mapsSupported => PlacePickerMap.isSupported;

  int get _playerCount =>
      _players.where((p) => _hasValidCoordinates(p.latitude, p.longitude)).length;

  int get _placeCount =>
      _places.where((p) => _hasValidCoordinates(p.latitude, p.longitude)).length;

  @override
  Widget build(BuildContext context) {
    final markers = _loading ? <Marker>{} : _buildMarkers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/players-search'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPlace,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Adicionar local'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: Text('Jogadores ($_playerCount)'),
                  selected: _showPlayers,
                  onSelected: (v) => setState(() => _showPlayers = v),
                  avatar: const Icon(Icons.person, size: 18),
                ),
                FilterChip(
                  label: Text('Lugares ($_placeCount)'),
                  selected: _showPlaces,
                  onSelected: (v) => setState(() => _showPlaces = v),
                  avatar: const Icon(Icons.place, size: 18),
                ),
              ],
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
                            showPlayers: _showPlayers,
                            showPlaces: _showPlaces,
                            players: _players,
                            places: _places,
                            onPlayerTap: (p) => context.push('/players/${p.id}'),
                            onPlaceTap: _openPlace,
                          )
                        : GoogleMap(
                            key: ValueKey('map_${markers.length}'),
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
    required this.showPlayers,
    required this.showPlaces,
    required this.players,
    required this.places,
    required this.onPlayerTap,
    required this.onPlaceTap,
  });

  final bool showPlayers;
  final bool showPlaces;
  final List<Player> players;
  final List<Place> places;
  final void Function(Player) onPlayerTap;
  final void Function(Place) onPlaceTap;

  @override
  Widget build(BuildContext context) {
  final visiblePlayers =
      players.where((p) => _hasValidCoordinates(p.latitude, p.longitude)).toList();
  final visiblePlaces =
      places.where((p) => _hasValidCoordinates(p.latitude, p.longitude)).toList();

    if (!showPlayers && !showPlaces) {
      return const EmptyState(
        icon: Icons.layers_clear,
        title: 'Nenhuma camada visível',
        subtitle: 'Ative jogadores ou locais nos filtros acima.',
      );
    }

    if (showPlayers && visiblePlayers.isEmpty && (!showPlaces || visiblePlaces.isEmpty)) {
      return const EmptyState(
        icon: Icons.map_outlined,
        title: 'Nada por perto',
        subtitle: 'Cadastre um local ou convide jogadores para aparecerem no mapa.',
      );
    }

    return ListView(
      children: [
        if (showPlayers) ...[
          const ListTile(
            title: Text('Jogadores', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (visiblePlayers.isEmpty)
            const ListTile(title: Text('Nenhum jogador por perto'))
          else
            ...visiblePlayers.map(
              (p) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.sports_tennis)),
                title: Text(p.name),
                subtitle: Text(
                  'NTRP ${p.ntrpRating.toStringAsFixed(1)} · ${p.distanceKm?.toStringAsFixed(1) ?? '?'} km',
                ),
                onTap: () => onPlayerTap(p),
              ),
            ),
        ],
        if (showPlaces) ...[
          const ListTile(
            title: Text('Locais', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (visiblePlaces.isEmpty)
            const ListTile(title: Text('Nenhum local cadastrado'))
          else
            ...visiblePlaces.map(
              (p) => ListTile(
                leading: const Icon(Icons.place, color: AppColors.navy),
                title: Text(p.name),
                subtitle: Text(p.subtitle),
                onTap: () => onPlaceTap(p),
              ),
            ),
        ],
      ],
    );
  }
}
