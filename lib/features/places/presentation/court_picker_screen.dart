import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/shared/models/nearby_court.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class CourtPickerScreen extends ConsumerStatefulWidget {
  const CourtPickerScreen({super.key, this.selectMode = false});

  final bool selectMode;

  @override
  ConsumerState<CourtPickerScreen> createState() => _CourtPickerScreenState();
}

class _CourtPickerScreenState extends ConsumerState<CourtPickerScreen> {
  AsyncValue<List<NearbyCourt>> _courts = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _load();
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
    setState(() => _courts = const AsyncLoading());
    try {
      final center = await _currentCenter();
      final list = await ref.read(placesRepositoryProvider).nearbyCourts(
            lat: center.lat,
            lng: center.lng,
          );
      if (!mounted) return;
      setState(() => _courts = AsyncData(list));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _courts = AsyncError(e, st));
    }
  }

  void _select(NearbyCourt court) {
    context.pop(court);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectMode ? 'Escolher quadra' : 'Quadras por perto'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _courts.when(
          loading: () => const LoadingView(message: 'Buscando quadras...'),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: _load),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.sports_tennis,
                    title: 'Nenhuma quadra encontrada por perto',
                    subtitle: 'Tente novamente mais tarde ou escolha outra região.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(12, 12, 12, screenBottomInset(context) + 12),
              itemCount: list.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final court = list[i];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      court.isGooglePlace ? Icons.map : Icons.place,
                      color: court.isGooglePlace ? AppColors.info : null,
                    ),
                    title: Text(court.name),
                    subtitle: Text(court.subtitle),
                    trailing: widget.selectMode ? const Icon(Icons.chevron_right) : null,
                    onTap: widget.selectMode ? () => _select(court) : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
