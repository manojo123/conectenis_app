import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/utils/debounce.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/chip_row.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class PlayersListScreen extends ConsumerStatefulWidget {
  const PlayersListScreen({super.key, this.selectMode = false});

  final bool selectMode;

  @override
  ConsumerState<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends ConsumerState<PlayersListScreen> {
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  final _searchDebouncer = Debouncer();
  double _minNtrp = 1.0;
  double _maxNtrp = 5.0;
  double _minAge = 18;
  double _maxAge = 60;
  int _genderIndex = 0; // 0 = todos
  int _sortIndex = 0;
  bool _filtersOpen = false;
  AsyncValue<List<Player>> _players = const AsyncLoading();
  List<Player> _cachedPlayers = [];

  static const _sortValues = ['distance', 'ntrp_desc', 'age_asc'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
    _cityController.addListener(_onQueryChanged);
    _load();
  }

  void _onQueryChanged() {
    _searchDebouncer.run(() => _load(initial: false));
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Gender? get _gender => switch (_genderIndex) {
        1 => Gender.male,
        2 => Gender.female,
        _ => null,
      };

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

  Future<void> _load({bool initial = true}) async {
    if (initial || _cachedPlayers.isEmpty) {
      setState(() => _players = const AsyncLoading());
    }
    try {
      final center = await _currentCenter();
      final list = await ref.read(playersRepositoryProvider).nearby(
            lat: center.lat,
            lng: center.lng,
            name: _searchController.text.trim(),
            city: _cityController.text.trim(),
            gender: _gender,
            minNtrp: _minNtrp,
            maxNtrp: _maxNtrp,
            minAge: _minAge.round(),
            maxAge: _maxAge.round(),
            sort: _sortValues[_sortIndex],
          );
      setState(() {
        _cachedPlayers = list;
        _players = AsyncData(list);
      });
    } catch (e, st) {
      setState(() => _players = AsyncError(e, st));
    }
  }

  Future<void> _openChat(BuildContext context, Player player) async {
    try {
      final conv =
          await ref.read(chatRepositoryProvider).start(player.id, player.name);
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
      showToast(context, e is ApiException ? e.message : e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Symbols.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: t.inputBg,
                        border: Border.all(color: t.border),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Symbols.search_rounded,
                              size: 19, color: t.muted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: !widget.selectMode,
                              decoration: InputDecoration(
                                hintText: 'Nome do jogador…',
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                hintStyle: TextStyle(
                                    fontSize: 14.5, color: t.muted),
                              ),
                              style:
                                  TextStyle(fontSize: 14.5, color: t.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleIconButton(
                    icon: Symbols.tune_rounded,
                    color: _filtersOpen ? t.accentText : t.muted,
                    onTap: () => setState(() => _filtersOpen = !_filtersOpen),
                    tooltip: 'Filtros',
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _filtersOpen
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _filters(t),
              secondChild: const SizedBox(width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  switch (_players) {
                    AsyncData(:final value) => value.length == 1
                        ? '1 jogador encontrado'
                        : '${value.length} jogadores encontrados',
                    _ => 'Buscando…',
                  },
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: t.muted,
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(initial: _cachedPlayers.isEmpty),
                child: _players.when(
                  loading: () {
                    if (_cachedPlayers.isNotEmpty) {
                      return _resultList(_cachedPlayers);
                    }
                    return const LoadingView();
                  },
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () => _load(initial: true),
                  ),
                  data: _resultList,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters(AppTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _filterRow(
            t,
            'CIDADE',
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: t.surface,
                  border: Border.all(color: t.border),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: 'Todas',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    hintStyle: TextStyle(fontSize: 12.5, color: t.muted),
                  ),
                  style: TextStyle(fontSize: 12.5, color: t.text),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          _filterRow(
            t,
            'IDADE',
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${_minAge.round()}–${_maxAge.round()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: t.text,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: _sliderTheme(t),
                      child: RangeSlider(
                        min: 10,
                        max: 80,
                        divisions: 70,
                        values: RangeValues(_minAge, _maxAge),
                        onChanged: (v) => setState(() {
                          _minAge = v.start;
                          _maxAge = v.end;
                        }),
                        onChangeEnd: (_) => _load(initial: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _filterRow(
            t,
            'NÍVEL',
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${ntrpValueLabel(_minNtrp)}–${ntrpValueLabel(_maxNtrp)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: t.text,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: _sliderTheme(t),
                      child: RangeSlider(
                        min: 1,
                        max: 5,
                        divisions: 8,
                        values: RangeValues(_minNtrp, _maxNtrp),
                        onChanged: (v) => setState(() {
                          _minNtrp = v.start;
                          _maxNtrp = v.end;
                        }),
                        onChangeEnd: (_) => _load(initial: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _filterRow(
            t,
            'SEXO',
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ChoiceChipRow(
                  options: const ['Todos', 'Masculino', 'Feminino'],
                  selectedIndex: _genderIndex,
                  dense: true,
                  onSelected: (i) {
                    setState(() => _genderIndex = i);
                    _load(initial: false);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          _filterRow(
            t,
            'ORDEM',
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ChoiceChipRow(
                  options: const ['Distância', 'Nível', 'Idade'],
                  selectedIndex: _sortIndex,
                  dense: true,
                  onSelected: (i) {
                    setState(() => _sortIndex = i);
                    _load(initial: false);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliderThemeData _sliderTheme(AppTokens t) {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: t.accent,
      inactiveTrackColor: t.surface2,
      thumbColor: t.accent,
      overlayColor: t.tintAcc,
      rangeThumbShape:
          const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
      trackHeight: 4,
    );
  }

  Widget _filterRow(AppTokens t, String label, Widget child) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: t.disabled,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _resultList(List<Player> list) {
    final t = context.t;
    if (list.isEmpty) {
      return EmptyState(
        icon: Symbols.group_rounded,
        title: 'Nenhum jogador encontrado',
        subtitle: widget.selectMode
            ? 'Amplie os filtros para ver mais jogadores.'
            : 'Ajuste os filtros ou volte mais tarde.',
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        14,
        2,
        14,
        MediaQuery.viewPaddingOf(context).bottom + 14,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final p = list[i];
        final subParts = <String>[
          if (p.age != null) '${p.age} anos',
          if ((p.profession ?? '').isNotEmpty) p.profession!,
        ];
        final metaParts = <String>[
          if (p.locationLabel.isNotEmpty) p.locationLabel,
          if (p.distanceKm != null)
            '${p.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
        ];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PressableScale(
            scale: 0.985,
            onTap: () => widget.selectMode
                ? context.pop(p)
                : context.push('/players/${p.id}'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.surface,
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
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
                            if (subParts.isNotEmpty)
                              Text(
                                subParts.join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(fontSize: 12, color: t.muted),
                              ),
                            if (metaParts.isNotEmpty)
                              Text(
                                metaParts.join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 12),
                  if (widget.selectMode)
                    LimeButton(
                      label: 'Selecionar',
                      onPressed: () => context.pop(p),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: PressableScale(
                            onTap: () => _openChat(context, p),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: t.border),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                'MENSAGEM',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: t.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PressableScale(
                            onTap: () => context.push(
                              '/challenges/new/direct?playerId=${p.id}',
                            ),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: t.accent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                'DESAFIAR',
                                style: TextStyle(
                                  fontSize: 12,
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
            ),
          ),
        );
      },
    );
  }
}
