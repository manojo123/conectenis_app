import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/features/courts/data/courts_repository.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class CourtsListScreen extends ConsumerStatefulWidget {
  const CourtsListScreen({super.key});

  @override
  ConsumerState<CourtsListScreen> createState() => _CourtsListScreenState();
}

class _CourtsListScreenState extends ConsumerState<CourtsListScreen> {
  AsyncValue _courts = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _courts = const AsyncLoading());
    try {
      final list = await ref.read(courtsRepositoryProvider).list(
            lat: MockData.centerLat,
            lng: MockData.centerLng,
          );
      setState(() => _courts = AsyncData(list));
    } catch (e, st) {
      setState(() => _courts = AsyncError(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quadras')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _courts.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: _load),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.sports_tennis,
                title: 'Nenhuma quadra encontrada',
              );
            }
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                return ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(c.name),
                  subtitle: Text('${c.address}${c.city != null ? ', ${c.city}' : ''}'),
                  trailing: Text(
                    c.distanceKm != null ? '${c.distanceKm!.toStringAsFixed(1)} km' : '',
                  ),
                  onTap: () => context.push('/courts/${c.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
