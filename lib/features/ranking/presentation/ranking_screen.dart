import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/ranking/data/rankings_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

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

  Widget _filterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Segmentação', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ChallengeFormat>(
            segments: ChallengeFormat.values
                .map((f) => ButtonSegment(value: f, label: Text(f.label)))
                .toList(),
            selected: {_format},
            onSelectionChanged: (s) {
              setState(() => _format = s.first);
              _load();
            },
          ),
          const SizedBox(height: 8),
          SegmentedButton<RankingGenderFilter>(
            segments: RankingGenderFilter.values
                .map((g) => ButtonSegment(value: g, label: Text(g.label)))
                .toList(),
            selected: {_gender},
            onSelectionChanged: (s) {
              setState(() => _gender = s.first);
              _load();
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<double>(
            initialValue: _ntrpLevel,
            decoration: const InputDecoration(
              labelText: 'Nível NTRP',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _ntrpOptions
                .map((n) => DropdownMenuItem(value: n, child: Text(n.toStringAsFixed(1))))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _ntrpLevel = v);
              _load();
            },
          ),
          const SizedBox(height: 8),
          SegmentedButton<RankingGeoScope>(
            segments: RankingGeoScope.values
                .map((g) => ButtonSegment(value: g, label: Text(g.label)))
                .toList(),
            selected: {_geo},
            onSelectionChanged: (s) {
              setState(() => _geo = s.first);
              _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _userPositionCard(RankingUserPosition position) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.08),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          child: Text('${position.rank}'),
        ),
        title: const Text('Sua posição neste ranking'),
        subtitle: Text('${position.points} pts · ${position.wins} vitórias'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final response = _response;
    final entries = response?.entries ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: Column(
        children: [
          _filterSection(),
          if (response?.segmentLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                response!.segmentLabel!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (response?.userPosition != null) _userPositionCard(response!.userPosition!),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : entries.isEmpty
                        ? const Center(child: Text('Nenhum jogador neste segmento ainda.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: entries.length,
                              itemBuilder: (_, i) {
                                final e = entries[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    child: Text('${e.rank}'),
                                  ),
                                  title: Text(e.player.name),
                                  subtitle: Text(
                                    'NTRP ${e.player.ntrpRating.toStringAsFixed(1)}'
                                    '${e.cityName != null ? ' · ${e.cityName}' : ''}',
                                  ),
                                  trailing: Text('${e.points} pts · ${e.wins} V'),
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
