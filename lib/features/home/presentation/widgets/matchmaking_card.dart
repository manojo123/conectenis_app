import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/features/home/data/dashboard_repository.dart';
import 'package:conectenis_app/features/home/models/dashboard_matchmaking.dart';
import 'package:conectenis_app/features/home/providers/dashboard_providers.dart';
import 'package:conectenis_app/shared/utils/app_share.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class MatchmakingCard extends ConsumerWidget {
  const MatchmakingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radiusKm = ref.watch(matchmakingRadiusProvider);
    final matchmakingAsync = ref.watch(dashboardMatchmakingProvider);

    return Card(
      color: AppColors.card,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.lime),
                const SizedBox(width: 8),
                Text(
                  'Matchmaking Local',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Jogadores do seu nível técnico na região',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            _RadiusSelector(
              selected: radiusKm,
              onChanged: (value) {
                ref.read(matchmakingRadiusProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),
            matchmakingAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: LoadingView(),
              ),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(dashboardMatchmakingProvider),
              ),
              data: (data) => _MatchmakingBody(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadiusSelector extends StatelessWidget {
  const _RadiusSelector({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: DashboardRepository.allowedRadiiKm
          .map((km) => ButtonSegment(value: km, label: Text('$km km')))
          .toList(),
      selected: {selected},
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _MatchmakingBody extends StatelessWidget {
  const _MatchmakingBody({required this.data});

  final DashboardMatchmaking data;

  @override
  Widget build(BuildContext context) {
    if (data.hasMatches) {
      return _HasMatchesContent(data: data);
    }
    return _EmptyMatchesContent(data: data);
  }
}

class _HasMatchesContent extends StatelessWidget {
  const _HasMatchesContent({required this.data});

  final DashboardMatchmaking data;

  String get _headline {
    final count = data.count;
    final playerWord = count == 1 ? 'jogador' : 'jogadores';
    return '$count $playerWord do seu nível a ${data.radiusKm} km';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lime.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _headline,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.lime,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'NTRP ${data.ntrpRating} — Hora de entrar em quadra! Desafie alguém agora.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LimeButton(
          label: 'Gerar Desafio Direto',
          icon: Icons.sports_tennis,
          onPressed: () => context.push('/challenges/new/direct'),
        ),
      ],
    );
  }
}

class _EmptyMatchesContent extends StatelessWidget {
  const _EmptyMatchesContent({required this.data});

  final DashboardMatchmaking data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seja o pioneiro da região!',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nenhum jogador NTRP ${data.ntrpRating} encontrado em ${data.radiusKm} km. '
                'Convide amigos e faça a comunidade local crescer.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LimeButton(
          label: 'Convidar amigos',
          icon: Icons.share,
          outlined: true,
          onPressed: () => AppShare.inviteFriends(),
        ),
      ],
    );
  }
}
