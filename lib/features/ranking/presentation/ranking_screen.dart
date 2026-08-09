import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/app/notification_bell_button.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/ranking/data/rankings_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:conectenis_app/shared/widgets/chip_row.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/segmented_tabs.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  RankingGeoScope _geo = RankingGeoScope.city;
  RankingGenderFilter _gender = RankingGenderFilter.all;
  ChallengeFormat _format = ChallengeFormat.singles;
  double _ntrpLevel = 4.0;
  RankingsResponse? _response;
  bool _loading = true;
  String? _error;

  static const _ntrpOptions = [2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 7.0];

  // Prototype scope order: Cidade · Estado · Brasil.
  static const _geoOrder = [
    RankingGeoScope.city,
    RankingGeoScope.state,
    RankingGeoScope.country,
  ];

  static const _medals = [Color(0xFFE8B931), Color(0xFFB9C2D6), Color(0xFFC77B4A)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromProfile());
  }

  void _initFromProfile() {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      setState(() {
        _ntrpLevel = _nearestNtrp(user.ntrpRating);
        _gender = RankingGenderFilter.fromUserGender(user.gender);
      });
    }
    _load();
  }

  double _nearestNtrp(double value) {
    return _ntrpOptions.reduce(
      (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = ref.read(authStateProvider).value;
      final response = await ref.read(rankingsRepositoryProvider).fetch(
            geo: _geo,
            ntrpLevel: _ntrpLevel,
            gender: _gender,
            format: _format,
            state: _geo == RankingGeoScope.state ? user?.state : null,
            cityId: _geo == RankingGeoScope.city ? user?.homeCityId : null,
          );
      setState(() {
        _response = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final response = _response;
    final entries = response?.entries ?? [];
    final currentUserId = ref.watch(authStateProvider).value?.id;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Rankings', trailing: NotificationBellButton()),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: SegmentedTabs(
                labels: _geoOrder.map((g) => g.label).toList(),
                index: _geoOrder.indexOf(_geo),
                onChanged: (i) {
                  setState(() => _geo = _geoOrder[i]);
                  _load();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Column(
                children: [
                  _filterRow(
                    t,
                    'FORMATO',
                    ChoiceChipRow(
                      options:
                          ChallengeFormat.values.map((f) => f.label).toList(),
                      selectedIndex: ChallengeFormat.values.indexOf(_format),
                      dense: true,
                      scrollable: true,
                      onSelected: (i) {
                        setState(() => _format = ChallengeFormat.values[i]);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _filterRow(
                    t,
                    'GÊNERO',
                    ChoiceChipRow(
                      options: RankingGenderFilter.values
                          .map((g) => g.label)
                          .toList(),
                      selectedIndex:
                          RankingGenderFilter.values.indexOf(_gender),
                      dense: true,
                      scrollable: true,
                      onSelected: (i) {
                        setState(
                            () => _gender = RankingGenderFilter.values[i]);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _filterRow(
                    t,
                    'NÍVEL',
                    ChoiceChipRow(
                      options: _ntrpOptions.map(ntrpValueLabel).toList(),
                      selectedIndex: _ntrpOptions.indexOf(_ntrpLevel),
                      dense: true,
                      scrollable: true,
                      onSelected: (i) {
                        setState(() => _ntrpLevel = _ntrpOptions[i]);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: entries.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 60),
                                    EmptyState(
                                      icon: Symbols.leaderboard_rounded,
                                      title:
                                          'Nenhum jogador neste segmento ainda',
                                      subtitle:
                                          'Jogue partidas avaliadas para entrar no ranking.',
                                    ),
                                  ],
                                )
                              : ListView(
                                  padding: EdgeInsets.fromLTRB(14, 4, 14,
                                      screenBottomInset(context) + 18),
                                  children: [
                                    if (response?.userPosition != null)
                                      _userPositionCard(
                                        t,
                                        response!.userPosition!,
                                        response.segmentLabel,
                                      ),
                                    if (entries.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      _podium(t, entries.take(3).toList()),
                                    ],
                                    const SizedBox(height: 12),
                                    _rowsCard(t, entries, currentUserId),
                                  ],
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow(AppTokens t, String label, Widget child) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: t.disabled,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _userPositionCard(
      AppTokens t, RankingUserPosition position, String? segmentLabel) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.tintAcc, t.tintAcc.withValues(alpha: 0)],
          stops: const [0, 0.7],
        ),
        color: t.surface,
        border: Border.all(color: t.accent),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(
            '#${position.rank}',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: t.accentText,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sua posição${segmentLabel != null ? ' · $segmentLabel' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${position.points} pts · ${position.wins} vitórias',
                  style: TextStyle(fontSize: 12, color: t.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _podium(AppTokens t, List<RankingEntry> top) {
    if (top.isEmpty) return const SizedBox.shrink();
    // Display order 2nd · 1st · 3rd, pedestal heights from the prototype.
    final order = <(RankingEntry, int, double)>[
      if (top.length > 1) (top[1], 1, 96),
      (top[0], 0, 124),
      if (top.length > 2) (top[2], 2, 80),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (entry, medalIndex, height) in order)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _medals[medalIndex],
                              width: 2.5,
                            ),
                          ),
                          child: UserAvatar(
                            name: entry.player.name,
                            avatarUrl: entry.player.avatarUrl,
                            hasCustomAvatar: entry.player.hasCustomAvatar,
                            userId: entry.player.id,
                            radius: 27,
                          ),
                        ),
                        Positioned(
                          top: -9,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _medals[medalIndex],
                                shape: BoxShape.circle,
                                border: Border.all(color: t.bg, width: 2),
                              ),
                              child: Text(
                                '${medalIndex + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F1A38),
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      entry.player.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: t.text,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: double.infinity,
                      height: height,
                      padding: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [t.surface2, t.surface2.withValues(alpha: 0)],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${entry.points}',
                        textAlign: TextAlign.center,
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
        ],
      ),
    );
  }

  Widget _rowsCard(AppTokens t, List<RankingEntry> entries, int? currentUserId) {
    final rest = entries.length > 3 ? entries.sublist(3) : <RankingEntry>[];
    if (rest.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (final e in rest) _rankRow(t, e, e.player.id == currentUserId),
        ],
      ),
    );
  }

  Widget _rankRow(AppTokens t, RankingEntry e, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? t.tintAcc : Colors.transparent,
        border: Border.all(color: isMe ? t.accent : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${e.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: t.muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          UserAvatar(
            name: e.player.name,
            avatarUrl: e.player.avatarUrl,
            hasCustomAvatar: e.player.hasCustomAvatar,
            userId: e.player.id,
            radius: 19,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'Você' : e.player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                  ),
                ),
                Text(
                  'NTRP ${ntrpValueLabel(e.player.ntrpRating)}'
                  '${e.cityName != null ? ' · ${e.cityName}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: t.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${e.points}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: t.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${e.wins} V',
                style: TextStyle(fontSize: 10.5, color: t.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
