import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/app/notification_bell_button.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/features/location/location_sync_controller.dart';
import 'package:conectenis_app/features/map/presentation/marker_bitmaps.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/nearby_court.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/frosted.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';
import 'package:conectenis_app/shared/widgets/segmented_tabs.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

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
  MapFilter _mode = MapFilter.players;
  Player? _selectedPlayer;
  Place? _selectedPlace;
  Set<Marker> _markers = {};
  String? _darkStyle;
  String? _lightStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyles();
    _initLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyles() async {
    final dark = await rootBundle.loadString('assets/map_styles/map_dark.json');
    final light =
        await rootBundle.loadString('assets/map_styles/map_light.json');
    if (mounted) {
      setState(() {
        _darkStyle = dark;
        _lightStyle = light;
      });
    }
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
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      _center = LatLng(pos.latitude, pos.longitude);
      await ref.read(locationSyncControllerProvider).syncCoordinates(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
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
      if (!mounted) return;
      setState(() {
        _players = results[0] as List<Player>;
        _places = results[1] as List<Place>;
        _loading = false;
        _error = null;
      });
      await _rebuildMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _rebuildMarkers() async {
    if (!_mapsSupported || !mounted) return;
    final t = context.t;
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(2.0, 4.0);
    final markers = <Marker>{};

    if (_mode == MapFilter.players) {
      for (final p in _players
          .where((p) => _hasValidCoordinates(p.latitude, p.longitude))) {
        final selected = _selectedPlayer?.id == p.id;
        markers.add(
          Marker(
            markerId: MarkerId('player_${p.id}'),
            position: LatLng(p.latitude, p.longitude),
            zIndexInt: selected ? 10 : 0,
            anchor: const Offset(0.5, 0.5),
            icon: await MarkerBitmaps.player(
                p: p, selected: selected, t: t, dpr: dpr),
            onTap: () => _select(player: p),
          ),
        );
      }
    } else {
      for (final q in _places
          .where((p) => _hasValidCoordinates(p.latitude, p.longitude))) {
        final selected = _selectedPlace?.id == q.id;
        markers.add(
          Marker(
            markerId: MarkerId('place_${q.id}'),
            position: LatLng(q.latitude, q.longitude),
            zIndexInt: selected ? 10 : 0,
            anchor: const Offset(0.5, 0.5),
            icon: await MarkerBitmaps.place(
              id: q.id,
              selected: selected,
              t: t,
              dpr: dpr,
              isOwn: q.isOwner,
            ),
            onTap: () => _select(place: q),
          ),
        );
      }
    }
    if (mounted) setState(() => _markers = markers);
  }

  void _select({Player? player, Place? place}) {
    setState(() {
      _selectedPlayer = player;
      _selectedPlace = place;
    });
    _rebuildMarkers();
  }

  void _clearSelection() {
    if (_selectedPlayer == null && _selectedPlace == null) return;
    _select();
  }

  Future<void> _addPlace() async {
    final created = await context.push<Place>('/places/new');
    if (!mounted) return;
    if (created != null) {
      setState(() => _mode = MapFilter.places);
      await _loadData();
      if (_hasValidCoordinates(created.latitude, created.longitude)) {
        await _moveCamera(
          LatLng(created.latitude, created.longitude),
          zoom: 15,
        );
      }
      if (mounted) {
        showToast(context, 'Local "${created.name}" adicionado ao mapa');
      }
    } else {
      await _loadData();
    }
  }

  Future<void> _messagePlayer(Player player) async {
    try {
      final conv =
          await ref.read(chatRepositoryProvider).start(player.id, player.name);
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
      showToast(context, e.toString());
    }
  }

  bool get _mapsSupported => Env.isGoogleMapsSupported;

  String get _mapUnavailableMessage {
    if (!Env.isGoogleMapsNativePlatform) {
      return 'O mapa interativo só funciona no Android e iOS. Aqui mostramos a lista.';
    }
    if (!Env.hasGoogleMapsApiKeyInEnv) {
      return 'Chave do Google Maps não encontrada no .env. Mostrando a lista.';
    }
    return 'Mapa indisponível neste dispositivo.';
  }

  List<Player> get _visiblePlayers => _players
      .where((p) => _hasValidCoordinates(p.latitude, p.longitude))
      .toList();

  List<Place> get _visiblePlaces => _places
      .where((p) => _hasValidCoordinates(p.latitude, p.longitude))
      .toList();

  String get _countLabel {
    if (_mode == MapFilter.players) {
      final n = _visiblePlayers.length;
      return n == 1
          ? '1 jogador num raio de 50 km'
          : '$n jogadores num raio de 50 km';
    }
    final n = _visiblePlaces.length;
    return n == 1 ? '1 quadra num raio de 50 km' : '$n quadras num raio de 50 km';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? ColoredBox(
                    color: t.mapBg,
                    child: const LoadingView(message: 'Carregando mapa...'),
                  )
                : _error != null
                    ? ColoredBox(
                        color: t.bg,
                        child:
                            ErrorView(message: _error!, onRetry: _initLocation),
                      )
                    : !_mapsSupported
                        ? _MapListFallback(
                            mode: _mode,
                            players: _visiblePlayers,
                            places: _visiblePlaces,
                            banner: _mapUnavailableMessage,
                            onPlayerTap: (p) => _select(player: p),
                            onPlaceTap: (q) => _select(place: q),
                          )
                        : GoogleMap(
                            initialCameraPosition:
                                CameraPosition(target: _center, zoom: 13),
                            style: isDark ? _darkStyle : _lightStyle,
                            markers: _markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            onTap: (_) => _clearSelection(),
                            onMapCreated: (controller) {
                              _mapController = controller;
                              _moveCamera(_center);
                            },
                          ),
          ),
          // Top chrome: search pill + theme toggle, then the mode toggle.
          Positioned(
            top: 0,
            left: 14,
            right: 14,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PressableScale(
                          onTap: () => context.push('/players-search'),
                          scale: 0.985,
                          child: Frosted(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: t.border),
                            boxShadow: t.shadow,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Symbols.search_rounded,
                                      size: 20, color: t.muted),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Buscar jogadores, bairros…',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14, color: t.muted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const NotificationBellButton(frosted: true, size: 46),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SegmentedTabs(
                        labels: const ['Jogadores', 'Quadras'],
                        index: _mode == MapFilter.players ? 0 : 1,
                        frosted: true,
                        dense: true,
                        onChanged: (i) {
                          setState(() {
                            _mode =
                                i == 0 ? MapFilter.players : MapFilter.places;
                            _selectedPlayer = null;
                            _selectedPlace = null;
                          });
                          _rebuildMarkers();
                        },
                      ),
                      const Spacer(),
                      Frosted(
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(color: t.border),
                        boxShadow: t.shadow,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _addPlace,
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Icon(Symbols.add_location_alt_rounded,
                                size: 20, color: t.muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom: selection card + count pill.
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _selectedPlayer != null
                      ? _PlayerSheetCard(
                          key: ValueKey('p${_selectedPlayer!.id}'),
                          player: _selectedPlayer!,
                          onProfile: () =>
                              context.push('/players/${_selectedPlayer!.id}'),
                          onMessage: () => _messagePlayer(_selectedPlayer!),
                          onChallenge: () => context.push(
                              '/challenges/new/direct?playerId=${_selectedPlayer!.id}'),
                        )
                      : _selectedPlace != null
                          ? _PlaceSheetCard(
                              key: ValueKey('q${_selectedPlace!.id}'),
                              place: _selectedPlace!,
                              onOpen: () => context
                                  .push('/places/${_selectedPlace!.id}')
                                  .then((_) => _loadData()),
                              onChallengeHere: () => context.push(
                                '/challenges/new/public',
                                extra: NearbyCourt(
                                  placeId: _selectedPlace!.id,
                                  name: _selectedPlace!.name,
                                  latitude: _selectedPlace!.latitude,
                                  longitude: _selectedPlace!.longitude,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
                if (!_loading && _error == null) ...[
                  const SizedBox(height: 10),
                  Frosted(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.border),
                    boxShadow: t.shadow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      child: Text(
                        _countLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: t.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSheetCard extends StatelessWidget {
  const _PlayerSheetCard({
    super.key,
    required this.player,
    required this.onProfile,
    required this.onMessage,
    required this.onChallenge,
  });

  final Player player;
  final VoidCallback onProfile;
  final VoidCallback onMessage;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final subParts = <String>[
      if (player.age != null) '${player.age} anos',
      if ((player.profession ?? '').isNotEmpty) player.profession!,
    ];
    final meta = <String>[
      if ((player.locationLabel).isNotEmpty) player.locationLabel,
      if (player.distanceKm != null)
        'a ${player.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km de você',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: t.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              UserAvatar(
                name: player.name,
                avatarUrl: player.avatarUrl,
                hasCustomAvatar: player.hasCustomAvatar,
                userId: player.id,
                radius: 27,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: t.text,
                      ),
                    ),
                    if (subParts.isNotEmpty)
                      Text(
                        subParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: t.muted),
                      ),
                    if (meta.isNotEmpty)
                      Text(
                        meta.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: t.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: t.tintAcc,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'NTRP ${ntrpValueLabel(player.ntrpRating)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: t.accentText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 100,
                child: PressableScale(
                  onTap: onProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ver perfil',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PressableScale(
                onTap: onMessage,
                child: Container(
                  width: 46,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Symbols.chat_bubble_rounded, size: 20, color: t.text),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 130,
                child: PressableScale(
                  onTap: onChallenge,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: t.glow,
                    ),
                    child: Text(
                      'DESAFIAR',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: t.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceSheetCard extends StatelessWidget {
  const _PlaceSheetCard({
    super.key,
    required this.place,
    required this.onOpen,
    required this.onChallengeHere,
  });

  final Place place;
  final VoidCallback onOpen;
  final VoidCallback onChallengeHere;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final meta = <String>[
      if (place.distanceKm != null)
        'a ${place.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
      if (place.averageRating != null)
        '★ ${place.averageRating!.toStringAsFixed(1)}',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: t.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.tintAcc,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Symbols.sports_tennis_rounded,
                    size: 26, fill: 1, color: t.accentText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: t.text,
                      ),
                    ),
                    Text(
                      place.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: t.muted),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: t.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 100,
                child: PressableScale(
                  onTap: onOpen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ver local',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 130,
                child: PressableScale(
                  onTap: onChallengeHere,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: t.glow,
                    ),
                    child: Text(
                      'CRIAR DESAFIO AQUI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: t.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapListFallback extends StatelessWidget {
  const _MapListFallback({
    required this.mode,
    required this.players,
    required this.places,
    required this.banner,
    required this.onPlayerTap,
    required this.onPlaceTap,
  });

  final MapFilter mode;
  final List<Player> players;
  final List<Place> places;
  final String banner;
  final void Function(Player) onPlayerTap;
  final void Function(Place) onPlaceTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final showingPlayers = mode == MapFilter.players;
    final isEmpty = showingPlayers ? players.isEmpty : places.isEmpty;

    return ColoredBox(
      color: t.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 138, 14, 220),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: t.tintInfo,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Symbols.info_rounded, size: 19, color: t.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    banner,
                    style: TextStyle(fontSize: 12.5, color: t.muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Text(
                showingPlayers
                    ? 'Nenhum jogador por perto.'
                    : 'Nenhuma quadra cadastrada por perto.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: t.muted),
              ),
            )
          else if (showingPlayers)
            ...players.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PressableScale(
                  onTap: () => onPlayerTap(p),
                  scale: 0.985,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.surface,
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: p.name,
                          avatarUrl: p.avatarUrl,
                          hasCustomAvatar: p.hasCustomAvatar,
                          userId: p.id,
                          radius: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: t.text,
                                ),
                              ),
                              Text(
                                'a ${p.distanceKm?.toStringAsFixed(1).replaceAll('.', ',') ?? '?'} km',
                                style:
                                    TextStyle(fontSize: 12, color: t.muted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: t.tintAcc,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            ntrpValueLabel(p.ntrpRating),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: t.accentText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            ...places.map(
              (q) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PressableScale(
                  onTap: () => onPlaceTap(q),
                  scale: 0.985,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.surface,
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.tintAcc,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Symbols.sports_tennis_rounded,
                              size: 22, fill: 1, color: t.accentText),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: t.text,
                                ),
                              ),
                              Text(
                                q.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(fontSize: 12, color: t.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Symbols.chevron_right_rounded,
                            size: 20, color: t.disabled),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
