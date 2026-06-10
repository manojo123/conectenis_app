import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/models/public_challenge_filters.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/features/home/data/dashboard_repository.dart';
import 'package:conectenis_app/features/home/providers/dashboard_providers.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/challenge_status_chip.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:intl/intl.dart';

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
  String? _lastAppliedRoute;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isPublicDeepLink =
          GoRouterState.of(context).uri.queryParameters['tab'] == 'public';
      if (isPublicDeepLink) {
        _applyRouteParamsIfNeeded();
      } else {
        _load();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyRouteParamsIfNeeded();
    });
  }

  void _applyRouteParamsIfNeeded() {
    final params = GoRouterState.of(context).uri.queryParameters;
    if (params['tab'] != 'public') return;

    final routeUri = GoRouterState.of(context).uri.toString();
    final needsTabSync =
        _tabs.index != 2 || _role != ChallengeListRole.publicNearby;
    final isNewRoute = _lastAppliedRoute != routeUri;

    if (_tabs.index != 2) {
      _tabs.index = 2;
    }
    if (_role != ChallengeListRole.publicNearby) {
      setState(() => _role = ChallengeListRole.publicNearby);
    }

    if (!isNewRoute && !needsTabSync) return;
    _lastAppliedRoute = routeUri;

    final radius = int.tryParse(params['radius_km'] ?? '');
    if (radius != null && DashboardRepository.allowedRadiiKm.contains(radius)) {
      final current = ref.read(publicChallengesFilterProvider);
      if (current.radiusKm != radius) {
        ref.read(publicChallengesFilterProvider.notifier).state =
            current.copyWith(radiusKm: radius);
      }
      if (ref.read(matchmakingRadiusProvider) != radius) {
        ref.read(matchmakingRadiusProvider.notifier).state = radius;
      }
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
      final filters = _role == ChallengeListRole.publicNearby
          ? ref.read(publicChallengesFilterProvider)
          : null;
      final list = await ref.read(challengesRepositoryProvider).list(
            _role,
            filters: filters,
          );
      if (!mounted) return;
      setState(() {
        _items = list;
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

  @override
  Widget build(BuildContext context) {
    ref.listen(challengesRefreshProvider, (previous, next) => _load());
    ref.listen(publicChallengesFilterProvider, (previous, next) {
      if (_role == ChallengeListRole.publicNearby && previous != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _load();
        });
      }
    });

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
          if (_role == ChallengeListRole.publicNearby)
            _PublicFiltersBar(
              onChanged: () => _load(),
            ),
          Expanded(
            child: _loading
                ? const LoadingView(message: 'Carregando desafios...')
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _items.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Center(child: Text('Nenhum desafio nesta lista.')),
                                ],
                              )
                            : ListView(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  screenBottomInset(context) + 16,
                                ),
                                children: _items.map(_ChallengeCard.new).toList(),
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PublicFiltersBar extends ConsumerWidget {
  const _PublicFiltersBar({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(publicChallengesFilterProvider);
    final notifier = ref.read(publicChallengesFilterProvider.notifier);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DashboardRepository.allowedRadiiKm.map((km) {
                final selected = filters.radiusKm == km;
                return ChoiceChip(
                  label: Text('$km km'),
                  selected: selected,
                  onSelected: (_) {
                    ref.read(matchmakingRadiusProvider.notifier).state = km;
                    notifier.state = filters.copyWith(radiusKm: km);
                    onChanged();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ChallengeFormat?>(
              initialValue: filters.format,
              decoration: const InputDecoration(
                labelText: 'Formato',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<ChallengeFormat?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...ChallengeFormat.values.map(
                  (f) => DropdownMenuItem(value: f, child: Text(f.label)),
                ),
              ],
              onChanged: (value) {
                notifier.state = filters.copyWith(
                  format: value,
                  clearFormat: value == null,
                );
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<double?>(
                    initialValue: filters.minNtrp,
                    decoration: const InputDecoration(
                      labelText: 'NTRP mín.',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<double?>(value: null, child: Text('—')),
                      for (var n = 1.0; n <= 5.0; n += 0.5)
                        DropdownMenuItem(value: n, child: Text(n.toStringAsFixed(1))),
                    ],
                    onChanged: (value) {
                      notifier.state = filters.copyWith(
                        minNtrp: value,
                        clearMinNtrp: value == null,
                      );
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<double?>(
                    initialValue: filters.maxNtrp,
                    decoration: const InputDecoration(
                      labelText: 'NTRP máx.',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<double?>(value: null, child: Text('—')),
                      for (var n = 1.0; n <= 5.0; n += 0.5)
                        DropdownMenuItem(value: n, child: Text(n.toStringAsFixed(1))),
                    ],
                    onChanged: (value) {
                      notifier.state = filters.copyWith(
                        maxNtrp: value,
                        clearMaxNtrp: value == null,
                      );
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar',
                hintText: 'Jogador, local ou mensagem',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (value) {
                notifier.state = filters.copyWith(search: value);
                onChanged();
              },
              onChanged: (value) {
                if (value.isEmpty && filters.search.isNotEmpty) {
                  notifier.state = filters.copyWith(search: '');
                  onChanged();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard(this.challenge);

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd/MM, HH:mm', 'pt_BR');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/challenges/${challenge.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.type == ChallengeType.public
                          ? '${challenge.format.label} ${challenge.minNtrp?.toStringAsFixed(1) ?? ''}'
                          : challenge.creator.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ChallengeStatusChip(status: challenge.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(df.format(challenge.scheduledStart)),
              if (challenge.place != null) Text('Local: ${challenge.place!.name}'),
              if (challenge.type == ChallengeType.public && challenge.candidatesCount > 0)
                Text('${challenge.candidatesCount} candidato(s)'),
            ],
          ),
        ),
      ),
    );
  }
}
