import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/core/theme/app_radii.dart';
import 'package:conectenis_app/core/theme/app_shadows.dart';
import 'package:conectenis_app/features/home/data/dashboard_repository.dart';
import 'package:conectenis_app/features/home/models/dashboard_matchmaking.dart';
import 'package:conectenis_app/features/home/providers/dashboard_providers.dart';
import 'package:conectenis_app/shared/utils/app_share.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';

String _errorMessage(Object error) {
  if (error is ApiException) return error.message;
  return error.toString();
}

bool _isLocationError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('localização') || lower.contains('localizacao');
}

class MatchmakingCard extends ConsumerWidget {
  const MatchmakingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radiusKm = ref.watch(matchmakingRadiusProvider);
    final matchmakingAsync = ref.watch(dashboardMatchmakingProvider);
    final data = matchmakingAsync.valueOrNull;
    final isInitialLoading = matchmakingAsync.isLoading && data == null;
    final isRefreshing = matchmakingAsync.isLoading && data != null;

    if (isInitialLoading) {
      return const _HeroShell(
        child: SizedBox(
          height: 280,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.textOnLime),
          ),
        ),
      );
    }

    if (matchmakingAsync.hasError && data == null) {
      return _HeroShell(
        child: _HeroErrorMessage(
          message: _errorMessage(matchmakingAsync.error!),
          onRetry: () => ref.read(dashboardMatchmakingProvider.notifier).refresh(),
        ),
      );
    }

    return _MatchmakingHero(
      data: data!,
      radiusKm: radiusKm,
      isRefreshing: isRefreshing,
      onRadiusChanged: (value) {
        ref.read(matchmakingRadiusProvider.notifier).state = value;
      },
    );
  }
}

class _HeroShell extends StatelessWidget {
  const _HeroShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.hero),
      ),
      child: child,
    );
  }
}

class _HeroErrorMessage extends StatelessWidget {
  const _HeroErrorMessage({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isLocation = _isLocationError(message);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          isLocation ? Icons.location_off : Icons.error_outline,
          color: AppColors.textOnLime,
          size: 36,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textOnLime,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        if (isLocation) ...[
          const SizedBox(height: 8),
          Text(
            'Permita o acesso à localização nas configurações do dispositivo '
            'ou faça login novamente após conceder permissão.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textOnLime.withValues(alpha: 0.75),
                ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        _HeroButton(
          label: 'Tentar novamente',
          icon: Icons.refresh,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _MatchmakingHero extends ConsumerWidget {
  const _MatchmakingHero({
    required this.data,
    required this.radiusKm,
    required this.onRadiusChanged,
    this.isRefreshing = false,
  });

  final DashboardMatchmaking data;
  final int radiusKm;
  final ValueChanged<int> onRadiusChanged;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'JOGADORES PRÓXIMOS',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.textOnLime,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '(MESMO NÍVEL)',
            textAlign: TextAlign.center,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.textOnLime,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isRefreshing ? 0.45 : 1,
                  child: Text(
                    '${data.count}',
                    textAlign: TextAlign.center,
                    style: textTheme.displayLarge?.copyWith(
                      color: AppColors.textOnLime,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      fontSize: 64,
                    ),
                  ),
                ),
                if (isRefreshing)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.textOnLime,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.count == 1 ? 'Tenista Ativo' : 'Tenistas Ativos',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textOnLime,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nível: ${ntrpLevelDisplay(data.ntrpRating)}',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textOnLime,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.textOnLime),
              const SizedBox(width: 4),
              Text(
                'Raio: $radiusKm km',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textOnLime,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _RadiusSelector(
            selected: radiusKm,
            onChanged: onRadiusChanged,
          ),
          const SizedBox(height: 20),
          _HeroButton(
            label: 'Buscar Partida',
            icon: Icons.sports_tennis,
            glow: true,
            onPressed: () {
              ref.read(matchmakingRadiusProvider.notifier).state = radiusKm;
              context.go('/map');
            },
          ),
          if (!data.hasMatches) ...[
            const SizedBox(height: 14),
            Text(
              'Nenhum jogador do seu nível neste raio. Veja o mapa ou convide amigos.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textOnLime.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 14),
            _HeroButton(
              label: 'Convidar amigos',
              icon: Icons.share,
              outlined: true,
              onPressed: () => AppShare.inviteFriends(),
            ),
          ],
        ],
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
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: DashboardRepository.allowedRadiiKm.map((km) {
        final isSelected = km == selected;
        return ChoiceChip(
          label: Text('$km km'),
          selected: isSelected,
          onSelected: (_) => onChanged(km),
          selectedColor: AppColors.chipSelectedBg,
          backgroundColor: AppColors.navy.withValues(alpha: 0.35),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.chipSelectedFg : AppColors.chipUnselectedFg,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.chipSelectedBg : AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        );
      }).toList(),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
    this.glow = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool outlined;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: glow && !outlined ? AppShadows.limeGlow : null,
        ),
        child: Material(
          color: outlined ? AppColors.navyDeep.withValues(alpha: 0) : AppColors.buttonOnLimeBg,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: outlined
                    ? Border.all(color: AppColors.buttonOnLimeBg, width: 2)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: outlined ? AppColors.buttonOnLimeBg : AppColors.buttonOnLimeFg,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: outlined ? AppColors.buttonOnLimeBg : AppColors.buttonOnLimeFg,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
