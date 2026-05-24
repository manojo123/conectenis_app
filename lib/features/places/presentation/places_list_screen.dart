import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/utils/debounce.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class PlacesListScreen extends ConsumerStatefulWidget {
  const PlacesListScreen({super.key, this.selectMode = false});

  final bool selectMode;

  @override
  ConsumerState<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends ConsumerState<PlacesListScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();
  AsyncValue<List<Place>> _places = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debouncer.run(_load);
  }

  Future<({double lat, double lng})> _currentCenter() async {
    double lat = MockData.centerLat;
    double lng = MockData.centerLng;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}
    return (lat: lat, lng: lng);
  }

  Future<void> _load() async {
    setState(() => _places = const AsyncLoading());
    try {
      final center = await _currentCenter();
      final list = await ref.read(placesRepositoryProvider).nearby(
            lat: center.lat,
            lng: center.lng,
            name: _searchController.text.trim(),
          );
      setState(() => _places = AsyncData(list));
    } catch (e, st) {
      setState(() => _places = AsyncError(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.selectMode ? 'Escolher local' : 'Buscar locais')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Digite o nome do local...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _places.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(message: e.toString(), onRetry: _load),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.place_outlined,
                      title: 'Nenhum local encontrado',
                      subtitle: 'Tente outro nome ou cadastre um novo local.',
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, screenBottomInset(context) + 12),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final place = list[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.place),
                          title: Text(place.name),
                          subtitle: Text(place.subtitle),
                          trailing: widget.selectMode ? const Icon(Icons.chevron_right) : null,
                          onTap: widget.selectMode
                              ? () => context.pop(place)
                              : () => context.push('/places/${place.id}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
