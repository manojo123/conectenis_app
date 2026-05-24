import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/gender_selector.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/utils/debounce.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class PlayersListScreen extends ConsumerStatefulWidget {
  const PlayersListScreen({super.key, this.selectMode = false});

  final bool selectMode;

  @override
  ConsumerState<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends ConsumerState<PlayersListScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();
  double _minNtrp = 1.0;
  double _maxNtrp = 5.0;
  final int _minAge = 18;
  final int _maxAge = 60;
  Gender? _gender;
  final String _sort = 'distance';
  AsyncValue<List<Player>> _players = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  void _onSearchChanged() {
    _debouncer.run(_load);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
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
    setState(() => _players = const AsyncLoading());
    try {
      final center = await _currentCenter();
      final list = await ref.read(playersRepositoryProvider).nearby(
            lat: center.lat,
            lng: center.lng,
            name: _searchController.text.trim(),
            gender: _gender,
            minNtrp: _minNtrp,
            maxNtrp: _maxNtrp,
            minAge: _minAge,
            maxAge: _maxAge,
            sort: _sort,
          );
      setState(() => _players = AsyncData(list));
    } catch (e, st) {
      setState(() => _players = AsyncError(e, st));
    }
  }

  void _selectPlayer(Player player) {
    context.pop(player);
  }

  Future<void> _openChat(BuildContext context, Player player) async {
    try {
      final conv = await ref.read(chatRepositoryProvider).start(player.id, player.name);
      if (!context.mounted) return;
      openChatThread(
        context,
        Conversation(
          id: conv.id,
          otherUserId: conv.otherUserId,
          otherUserName: conv.otherUserName,
          lastMessage: conv.lastMessage,
          updatedAt: conv.updatedAt,
          otherAvatarUrl: player.avatarUrl ?? conv.otherAvatarUrl,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.selectMode ? 'Escolher adversário' : 'Busca por Jogadores';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: widget.selectMode
                          ? 'Buscar por nome...'
                          : 'Digite o nome do jogador...',
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _showFilters,
                  icon: const Icon(Icons.tune),
                  label: const Text('FILTRAR'),
                ),
              ],
            ),
          ),
          if (widget.selectMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mostrando jogadores perto de você. Use a busca por nome para filtrar.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _players.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(message: e.toString(), onRetry: _load),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.people_outline,
                      title: 'Nenhum jogador encontrado',
                      subtitle: widget.selectMode
                          ? 'Amplie os filtros ou busque por outro nome.'
                          : 'Ajuste os filtros ou volte mais tarde.',
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      MediaQuery.viewPaddingOf(context).bottom + 12,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: widget.selectMode ? () => _selectPlayer(p) : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    UserAvatar(
                                      name: p.name,
                                      avatarUrl: p.avatarUrl,
                                      radius: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          Text('NTRP: ${p.ntrpRating.toStringAsFixed(1)}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (p.city != null) Text('Cidade: ${p.city}'),
                                if (p.profession != null) Text('Profissão: ${p.profession}'),
                                if (p.distanceKm != null)
                                  Text('Distância: ${p.distanceKm!.toStringAsFixed(1)} km'),
                                const SizedBox(height: 8),
                                if (widget.selectMode)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _selectPlayer(p),
                                      child: const Text('Selecionar'),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _openChat(context, p),
                                          icon: const Icon(Icons.chat, size: 18),
                                          label: const Text('MENSAGEM'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => context.push(
                                            '/challenges/new/direct?playerId=${p.id}',
                                          ),
                                          icon: const Icon(Icons.sports_tennis, size: 18),
                                          label: const Text('DESAFIAR'),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
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

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.viewPaddingOf(ctx).bottom + 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Text('NTRP $_minNtrp - $_maxNtrp'),
              RangeSlider(
                min: 1,
                max: 5,
                divisions: 8,
                values: RangeValues(_minNtrp, _maxNtrp),
                onChanged: (v) => setModalState(() {
                  _minNtrp = v.start;
                  _maxNtrp = v.end;
                }),
              ),
              DropdownButtonFormField<Gender?>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Sexo'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...Gender.values.map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Row(
                        children: [
                          Icon(genderIcon(g), size: 22),
                          const SizedBox(width: 8),
                          Text(g.label),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setModalState(() => _gender = v),
              ),
              const SizedBox(height: 20),
              LimeButton(
                label: 'Buscar jogadores',
                onPressed: () {
                  Navigator.pop(ctx);
                  _load();
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
