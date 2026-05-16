import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class PlayersListScreen extends ConsumerStatefulWidget {
  const PlayersListScreen({super.key});

  @override
  ConsumerState<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends ConsumerState<PlayersListScreen> {
  SkillLevel? _skill;
  int _minAge = 18;
  int _maxAge = 60;
  AsyncValue<List<Player>> _players = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _players = const AsyncLoading());
    try {
      final list = await ref.read(playersRepositoryProvider).nearby(
            lat: MockData.centerLat,
            lng: MockData.centerLng,
            skill: _skill,
            minAge: _minAge,
            maxAge: _maxAge,
          );
      setState(() => _players = AsyncData(list));
    } catch (e, st) {
      setState(() => _players = AsyncError(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jogadores'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilters),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _players.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: _load),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.people_outline,
                title: 'Nenhum jogador encontrado',
                subtitle: 'Ajuste os filtros ou volte mais tarde.',
              );
            }
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(p.name[0])),
                  title: Text(p.name),
                  subtitle: Text(
                    '${p.skillLevel.label} · ${p.age ?? '?'} anos · ${p.playStyle.label}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/players/${p.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<SkillLevel?>(
                value: _skill,
                decoration: const InputDecoration(labelText: 'Nível'),
                items: [
                  const DropdownMenuItem(child: Text('Todos')),
                  ...SkillLevel.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  ),
                ],
                onChanged: (v) => setModalState(() => _skill = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '$_minAge',
                      decoration: const InputDecoration(labelText: 'Idade mín.'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _minAge = int.tryParse(v) ?? 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: '$_maxAge',
                      decoration: const InputDecoration(labelText: 'Idade máx.'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _maxAge = int.tryParse(v) ?? 60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _load();
                },
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
