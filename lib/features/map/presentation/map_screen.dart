import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/features/courts/data/courts_repository.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/court.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

final mapFilterProvider = StateProvider<MapFilter>((ref) => MapFilter.players);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng _center = const LatLng(MockData.centerLat, MockData.centerLng);
  bool _loading = true;
  String? _error;
  List<Player> _players = [];
  List<Court> _courts = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
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
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
      await _loadData();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final playersRepo = ref.read(playersRepositoryProvider);
      final courtsRepo = ref.read(courtsRepositoryProvider);
      final results = await Future.wait([
        playersRepo.nearby(lat: _center.latitude, lng: _center.longitude),
        courtsRepo.list(lat: _center.latitude, lng: _center.longitude),
      ]);
      setState(() {
        _players = results[0] as List<Player>;
        _courts = results[1] as List<Court>;
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
    return _courts
        .map(
          (c) => Marker(
            markerId: MarkerId('court_${c.id}'),
            position: LatLng(c.latitude, c.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: c.name),
            onTap: () => context.push('/courts/${c.id}'),
          ),
        )
        .toSet();
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

  bool get _mapsSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS) && Env.googleMapsApiKey.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(mapFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<MapFilter>(
              segments: const [
                ButtonSegment(value: MapFilter.players, label: Text('Jogadores'), icon: Icon(Icons.person)),
                ButtonSegment(value: MapFilter.courts, label: Text('Quadras'), icon: Icon(Icons.sports_tennis)),
              ],
              selected: {filter},
              onSelectionChanged: (s) => ref.read(mapFilterProvider.notifier).state = s.first,
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
                            courts: _courts,
                            onPlayerTap: (p) => context.push('/players/${p.id}'),
                            onCourtTap: (c) => context.push('/courts/${c.id}'),
                          )
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(target: _center, zoom: 13),
                            markers: _buildMarkers(filter),
                            myLocationEnabled: true,
                            onMapCreated: (_) {},
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
    required this.courts,
    required this.onPlayerTap,
    required this.onCourtTap,
  });

  final MapFilter filter;
  final List<Player> players;
  final List<Court> courts;
  final void Function(Player) onPlayerTap;
  final void Function(Court) onCourtTap;

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
    if (courts.isEmpty) {
      return const EmptyState(
        icon: Icons.sports_tennis,
        title: 'Nenhuma quadra cadastrada',
        subtitle: 'Em breve mais quadras na sua região.',
      );
    }
    return ListView.builder(
      itemCount: courts.length,
      itemBuilder: (_, i) {
        final c = courts[i];
        return ListTile(
          leading: const Icon(Icons.place, color: AppColors.navy),
          title: Text(c.name),
          subtitle: Text(c.address),
          onTap: () => onCourtTap(c),
        );
      },
    );
  }
}
