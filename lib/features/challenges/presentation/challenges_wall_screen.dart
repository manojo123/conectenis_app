import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/presentation/widgets/challenge_history_section.dart';
import 'package:conectenis_app/features/challenges/presentation/widgets/challenge_mural_card.dart';
import 'package:conectenis_app/features/challenges/presentation/widgets/challenges_wall_filters.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/features/challenges/utils/challenge_wall_utils.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/app_snackbar.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

/// Default public challenge search radius (km). Backend config target: 50.
const kPublicNearbyDefaultRadiusKm = 50;

class ChallengesWallScreen extends ConsumerStatefulWidget {
  const ChallengesWallScreen({super.key});

  @override
  ConsumerState<ChallengesWallScreen> createState() => _ChallengesWallScreenState();
}

class _ChallengesWallScreenState extends ConsumerState<ChallengesWallScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  ChallengeListRole _role = ChallengeListRole.created;
  List<Challenge> _items = [];
  bool _loading = true;
  String? _error;
  bool _appliedPublicDeepLink = false;
  ChallengesWallFilters _filters = const ChallengesWallFilters();
  final Set<int> _applyingIds = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyPublicTabDeepLinkIfNeeded();
      if (!_appliedPublicDeepLink) {
        _load();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyPublicTabDeepLinkIfNeeded();
    });
  }

  void _applyPublicTabDeepLinkIfNeeded() {
    final params = GoRouterState.of(context).uri.queryParameters;
    if (params['tab'] != 'public') return;
    if (_appliedPublicDeepLink && _tabs.index == 2) return;

    _appliedPublicDeepLink = true;
    if (_tabs.index != 2) {
      _tabs.index = 2;
    }
    if (_role != ChallengeListRole.publicNearby) {
      setState(() => _role = ChallengeListRole.publicNearby);
    }
    _load();
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging) {
      setState(() {
        _role = switch (_tabs.index) {
          0 => ChallengeListRole.created,
          1 => ChallengeListRole.received,
          _ => ChallengeListRole.publicNearby,
        };
      });
      _load();
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(challengesRepositoryProvider).list(
            _role,
            statuses: _filters.statuses.isEmpty ? null : _filters.statuses,
            scheduledFrom: _filters.scheduledFrom,
            scheduledTo: _filters.scheduledTo,
            includeHistory: _filters.includeHistory,
            sort: ChallengeListSort.priority,
            radiusKm: _role == ChallengeListRole.publicNearby
                ? kPublicNearbyDefaultRadiusKm
                : null,
          );
      if (!mounted) return;
      setState(() {
        _items = _applyClientFilters(list);
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

  /// Client-side fallback when backend does not yet filter/sort.
  List<Challenge> _applyClientFilters(List<Challenge> raw) {
    var items = raw;
    items = filterChallengesByStatus(items, _filters.statuses.isEmpty ? null : _filters.statuses);
    items = filterChallengesByDateRange(
      items,
      from: _filters.scheduledFrom,
      to: _filters.scheduledTo,
    );
    if (!_filters.includeHistory) {
      items = items.where((c) => !isChallengeHistory(c)).toList();
    }
    return sortChallengesByPriority(items);
  }

  Future<void> _applyToChallenge(Challenge challenge) async {
    setState(() => _applyingIds.add(challenge.id));
    try {
      await ref.read(challengesRepositoryProvider).apply(challenge.id);
      bumpChallengesRefresh(ref);
      await _load();
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Candidatura enviada!');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showDanger(context, e.toString());
    } finally {
      if (mounted) setState(() => _applyingIds.remove(challenge.id));
    }
  }

  String _emptyMessage() {
    return switch (_role) {
      ChallengeListRole.publicNearby =>
        'Nenhum desafio público disponível para o seu perfil no raio de $kPublicNearbyDefaultRadiusKm km.',
      ChallengeListRole.received => 'Nenhum desafio recebido no momento.',
      _ => 'Nenhum desafio criado no momento.',
    };
  }

  Widget _sectionHeader(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          if (subtitle != null)
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildCreatedList() {
    final parts = partitionChallenges(_items, includeHistory: true);
    if (parts.actionable.isEmpty && parts.history.isEmpty) {
      return _emptyList();
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, screenBottomInset(context) + 16),
      children: [
        ...parts.actionable.map(
          (c) => ChallengeMuralCard(challenge: c),
        ),
        ChallengeHistorySection(
          items: parts.history,
          cardBuilder: (c) => ChallengeMuralCard(challenge: c),
        ),
      ],
    );
  }

  Widget _buildReceivedList() {
    final direct = _items.where((c) => c.type == ChallengeType.direct).toList();
    final other = _items.where((c) => c.type != ChallengeType.direct).toList();

    if (direct.isEmpty && other.isEmpty) return _emptyList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, screenBottomInset(context) + 16),
      children: [
        if (direct.isNotEmpty) ...[
          _sectionHeader(
            'Desafios Diretos',
            subtitle: 'Convites enviados especificamente para você',
          ),
          ...direct.map(
            (c) => ChallengeMuralCard(challenge: c, highlightDirect: true),
          ),
        ],
        if (other.isNotEmpty) ...[
          if (direct.isNotEmpty) const SizedBox(height: 16),
          _sectionHeader('Outros recebidos'),
          ...other.map((c) => ChallengeMuralCard(challenge: c)),
        ],
      ],
    );
  }

  Widget _buildPublicList() {
    if (_items.isEmpty) return _emptyList();
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, screenBottomInset(context) + 16),
      children: [
        _sectionHeader(
          'Desafios Públicos',
          subtitle: 'Na sua região · até $kPublicNearbyDefaultRadiusKm km',
        ),
        ..._items.map(
          (c) => ChallengeMuralCard(
            challenge: c,
            showApplyButton: true,
            applying: _applyingIds.contains(c.id),
            onApply: () => _applyToChallenge(c),
          ),
        ),
      ],
    );
  }

  Widget _emptyList() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(child: Text(_emptyMessage())),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(message: 'Carregando desafios...');
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: switch (_role) {
        ChallengeListRole.created => _buildCreatedList(),
        ChallengeListRole.received => _buildReceivedList(),
        ChallengeListRole.publicNearby => _buildPublicList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(challengesRefreshProvider, (previous, next) => _load());

    final showFilters = _role == ChallengeListRole.created || _role == ChallengeListRole.received;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural de Desafios'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'CRIADOS'),
            Tab(text: 'RECEBIDOS'),
            Tab(text: 'PÚBLICOS'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (showFilters)
            ChallengeWallFilterBar(
              filters: _filters,
              onChanged: (f) {
                setState(() => _filters = f);
                _load();
              },
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
