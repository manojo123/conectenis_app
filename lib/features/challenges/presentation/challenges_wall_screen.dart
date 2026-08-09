import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/app/notification_bell_button.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/presentation/widgets/challenge_mural_card.dart';
import 'package:conectenis_app/features/challenges/presentation/widgets/challenges_wall_filters.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/features/challenges/utils/challenge_wall_utils.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/segmented_tabs.dart';

/// Default public challenge search radius (km). Backend config target: 50.
const kPublicNearbyDefaultRadiusKm = 50;

enum _WallTab { meus, mural, historico }

class ChallengesWallScreen extends ConsumerStatefulWidget {
  const ChallengesWallScreen({super.key});

  @override
  ConsumerState<ChallengesWallScreen> createState() => _ChallengesWallScreenState();
}

class _ChallengesWallScreenState extends ConsumerState<ChallengesWallScreen> {
  _WallTab _tab = _WallTab.meus;
  List<Challenge> _created = [];
  List<Challenge> _received = [];
  List<Challenge> _public = [];
  bool _loading = true;
  String? _error;
  bool _appliedPublicDeepLink = false;
  ChallengesWallFilters _filters = const ChallengesWallFilters();
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyPublicTabDeepLinkIfNeeded();
      _load();
    });
  }

  void _applyPublicTabDeepLinkIfNeeded() {
    final params = GoRouterState.of(context).uri.queryParameters;
    if (params['tab'] != 'public' || _appliedPublicDeepLink) return;
    _appliedPublicDeepLink = true;
    setState(() => _tab = _WallTab.mural);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(challengesRepositoryProvider);
      final results = await Future.wait([
        repo.list(ChallengeListRole.created, includeHistory: true),
        repo.list(ChallengeListRole.received, includeHistory: true),
        repo.list(
          ChallengeListRole.publicNearby,
          radiusKm: kPublicNearbyDefaultRadiusKm,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _created = results[0];
        _received = results[1];
        _public = results[2];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Challenge> _applyFilters(List<Challenge> raw) {
    var items = raw;
    items = filterChallengesByStatus(
        items, _filters.statuses.isEmpty ? null : _filters.statuses);
    items = filterChallengesByDateRange(
      items,
      from: _filters.scheduledFrom,
      to: _filters.scheduledTo,
    );
    return sortChallengesByPriority(items);
  }

  /// Public challenges available to me. Hides any with a gender preference
  /// that doesn't match mine — the backend's `public_nearby` list doesn't
  /// filter this server-side yet (see docs/BACKEND_PROMPT_REDESIGN.md), so
  /// without this a challenge could show up for everyone while only
  /// `can_apply` silently blocked the mismatched genders from joining.
  List<Challenge> get _muralItems {
    final myGender = ref.read(authStateProvider).value?.gender;
    return _public.where((c) {
      final pref = c.genderPreference;
      if (pref == null || pref.isEmpty) return true;
      return myGender != null && pref == myGender.value;
    }).toList();
  }

  /// Everything I'm part of that isn't history yet: challenges I created,
  /// public ones I've joined, and direct invites sent to me - including
  /// ones still awaiting my Aceitar/Recusar.
  List<Challenge> get _meusItems {
    final mine = <Challenge>[
      ..._created.where((c) => !isChallengeHistory(c)),
      ..._received.where((c) => !isChallengeHistory(c)),
    ];
    final seen = <int>{};
    return _applyFilters(
        mine.where((c) => seen.add(c.id)).toList(growable: false));
  }

  List<Challenge> get _historicoItems {
    final all = <Challenge>[
      ..._created.where(isChallengeHistory),
      ..._received.where(isChallengeHistory),
    ];
    final seen = <int>{};
    return _applyFilters(
        all.where((c) => seen.add(c.id)).toList(growable: false));
  }

  Future<void> _runAction(
    Challenge challenge,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyIds.add(challenge.id));
    try {
      await action();
      bumpChallengesRefresh(ref);
      await _load();
      if (mounted) showToast(context, successMessage);
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busyIds.remove(challenge.id));
    }
  }

  List<Widget> _cardActions(Challenge c) {
    final repo = ref.read(challengesRepositoryProvider);
    final busy = _busyIds.contains(c.id);
    final user = ref.read(authStateProvider).value;
    final isMine = user != null && c.creator.id == user.id;

    switch (_tab) {
      case _WallTab.mural:
        if (c.hasApplied) {
          return const [
            CardActionButton(
              label: 'Candidatura enviada',
              kind: CardActionKind.disabled,
              onTap: null,
            ),
          ];
        }
        if (!c.canApply) {
          return const [
            CardActionButton(
              label: 'Não disponível para o seu perfil',
              kind: CardActionKind.disabled,
              onTap: null,
            ),
          ];
        }
        return [
          CardActionButton(
            label: 'Candidatar-se',
            kind: CardActionKind.primary,
            loading: busy,
            onTap: busy
                ? null
                : () => _runAction(
                    c, () => repo.apply(c.id), 'Candidatura enviada!'),
          ),
        ];
      case _WallTab.meus:
        if (c.status == ChallengeStatus.pendingAcceptance &&
            c.role == 'received') {
          return [
            CardActionButton(
              label: 'Recusar',
              kind: CardActionKind.danger,
              loading: busy,
              onTap: busy
                  ? null
                  : () => _runAction(
                      c, () => repo.decline(c.id), 'Desafio recusado.'),
            ),
            CardActionButton(
              label: 'Aceitar',
              kind: CardActionKind.primary,
              loading: busy,
              onTap: busy
                  ? null
                  : () => _runAction(c, () => repo.accept(c.id),
                      'Desafio aceito! Partida agendada.'),
            ),
          ];
        }
        final actions = <Widget>[];
        if (isMine &&
            c.type == ChallengeType.public &&
            (c.status == ChallengeStatus.pendingCandidates ||
                c.status == ChallengeStatus.candidatesAwaitingAccept)) {
          actions.add(
            CardActionButton(
              label: 'Ver candidatos (${c.candidatesCount})',
              kind: CardActionKind.accentOutline,
              onTap: () => context.push('/challenges/${c.id}/candidates'),
            ),
          );
        }
        if (c.canSubmitResult) {
          actions.add(
            CardActionButton(
              label: 'Avaliar partida',
              kind: CardActionKind.primary,
              onTap: () => context.push('/challenges/${c.id}/evaluation'),
            ),
          );
        } else if (c.canApproveResult) {
          actions.add(
            CardActionButton(
              label: 'Aprovar resultado',
              kind: CardActionKind.primary,
              onTap: () =>
                  context.push('/challenges/${c.id}/approve-evaluation'),
            ),
          );
        } else if (c.status == ChallengeStatus.accepted) {
          actions.add(
            CardActionButton(
              label: 'Detalhes',
              kind: CardActionKind.primary,
              onTap: () => context.push('/challenges/${c.id}'),
            ),
          );
        }
        return actions;
      case _WallTab.historico:
        return const [];
    }
  }

  (String, String) get _emptyCopy => switch (_tab) {
        _WallTab.meus => (
            'Você ainda não tem jogos ativos',
            'Crie um desafio com o botão NOVO acima ou candidate-se no Mural.'
          ),
        _WallTab.mural => (
            'O mural está vazio por enquanto',
            'Nenhum desafio público disponível num raio de $kPublicNearbyDefaultRadiusKm km.'
          ),
        _WallTab.historico => (
            'Nada por aqui ainda',
            'Suas partidas concluídas aparecem aqui.'
          ),
      };

  @override
  Widget build(BuildContext context) {
    ref.listen(challengesRefreshProvider, (previous, next) => _load());
    final t = context.t;
    final user = ref.watch(authStateProvider).value;

    const segmentLabels = ['Meus jogos', 'Mural', 'Histórico'];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Desafios',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: t.text,
                      ),
                    ),
                  ),
                  const NotificationBellButton(),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleIconButton(
                        icon: Symbols.tune_rounded,
                        color: _filters.hasActiveFilters
                            ? t.accentText
                            : t.muted,
                        onTap: _openFilterSheet,
                        tooltip: 'Filtros',
                      ),
                      if (_filters.hasActiveFilters)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: t.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: t.bg, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  PressableScale(
                    scale: 0.96,
                    onTap: _showCreateMenu,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: t.glow,
                      ),
                      child: Row(
                        children: [
                          Icon(Symbols.add_rounded,
                              size: 18, weight: 700, color: t.onAccent),
                          const SizedBox(width: 4),
                          Text(
                            'NOVO',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: t.onAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: SegmentedTabs(
                labels: segmentLabels,
                index: _tab.index,
                dense: true,
                onChanged: (i) => setState(() => _tab = _WallTab.values[i]),
              ),
            ),
            Expanded(child: _buildBody(user?.id)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(int? userId) {
    if (_loading) {
      return const LoadingView(message: 'Carregando desafios...');
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final items = switch (_tab) {
      _WallTab.meus => _meusItems,
      _WallTab.mural => _muralItems,
      _WallTab.historico => _historicoItems,
    };

    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: Symbols.sports_tennis_rounded,
                  title: _emptyCopy.$1,
                  subtitle: _emptyCopy.$2,
                ),
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                  14, 2, 14, screenBottomInset(context) + 16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final c = items[i];
                return ChallengeMuralCard(
                  challenge: c,
                  currentUserId: userId,
                  highlightDirect:
                      c.type == ChallengeType.direct &&
                          c.status == ChallengeStatus.pendingAcceptance &&
                          c.role == 'received',
                  actions: _cardActions(c),
                );
              },
            ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FilterSheet(
        filters: _filters,
        onChanged: (f) => setState(() => _filters = f),
      ),
    );
  }

  void _showCreateMenu() {
    final t = context.t;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Novo desafio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 14),
              _CreateOption(
                icon: Symbols.person_rounded,
                title: 'Desafio direto',
                subtitle: 'Convide um jogador específico. Só ele verá o desafio.',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/challenges/new/direct');
                },
              ),
              const SizedBox(height: 8),
              _CreateOption(
                icon: Symbols.public_rounded,
                title: 'Desafio público',
                subtitle:
                    'Publicado no mural para jogadores do nível escolhido se candidatarem.',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/challenges/new/public');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PressableScale(
      scale: 0.985,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface2,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.tintAcc,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: t.accentText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: t.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: t.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right_rounded, size: 20, color: t.disabled),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filters, required this.onChanged});

  final ChallengesWallFilters filters;
  final ValueChanged<ChallengesWallFilters> onChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ChallengesWallFilters _local = widget.filters;

  static const _filterableStatuses = [
    ChallengeStatus.pendingAcceptance,
    ChallengeStatus.pendingCandidates,
    ChallengeStatus.candidatesAwaitingAccept,
    ChallengeStatus.accepted,
    ChallengeStatus.pendingScore,
    ChallengeStatus.pendingResultApproval,
    ChallengeStatus.completed,
    ChallengeStatus.cancelled,
    ChallengeStatus.declined,
    ChallengeStatus.expired,
  ];

  void _update(ChallengesWallFilters next) {
    setState(() => _local = next);
    widget.onChanged(next);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange:
          _local.scheduledFrom != null && _local.scheduledTo != null
              ? DateTimeRange(
                  start: _local.scheduledFrom!, end: _local.scheduledTo!)
              : null,
      locale: const Locale('pt', 'BR'),
    );
    if (range == null) return;
    _update(_local.copyWith(scheduledFrom: range.start, scheduledTo: range.end));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: t.text,
                    ),
                  ),
                ),
                if (_local.hasActiveFilters)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _update(const ChallengesWallFilters()),
                    child: Text(
                      'Limpar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: t.accentText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'DATA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: t.disabled,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                decoration: BoxDecoration(
                  color: t.surface2,
                  border: Border.all(color: t.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.calendar_month_rounded,
                        size: 18, color: t.muted),
                    const SizedBox(width: 9),
                    Text(
                      _local.scheduledFrom != null && _local.scheduledTo != null
                          ? '${_fmt(_local.scheduledFrom!)} – ${_fmt(_local.scheduledTo!)}'
                          : 'Qualquer data',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _local.scheduledFrom != null ? t.text : t.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'STATUS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: t.disabled,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final s in _filterableStatuses)
                  GestureDetector(
                    onTap: () {
                      final next = Set<ChallengeStatus>.from(_local.statuses);
                      if (!next.remove(s)) next.add(s);
                      _update(_local.copyWith(statuses: next));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _local.statuses.contains(s)
                            ? t.accent
                            : t.surface2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _local.statuses.contains(s)
                              ? Colors.transparent
                              : t.border,
                        ),
                      ),
                      child: Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _local.statuses.contains(s)
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: _local.statuses.contains(s)
                              ? t.onAccent
                              : t.muted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
