import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/utils/player_navigation.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class ChallengeParticipantsVersus extends ConsumerWidget {
  const ChallengeParticipantsVersus({
    super.key,
    required this.challenge,
  });

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = challenge.teamsForDisplay();
    if (teams.length < 2 || teams.any((t) => t.isEmpty)) {
      return _FlatFallback(challenge: challenge);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kDebugMode && !challenge.hasTeamData)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Times não informados pela API — layout estimado.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Row(
              children: [
                Expanded(child: _TeamSide(players: teams[0], ref: ref, context: context)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'X',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: _TeamSide(players: teams[1], ref: ref, context: context)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({
    required this.players,
    required this.ref,
    required this.context,
  });

  final List<Player> players;
  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final isDoubles = players.length > 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDoubles)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: players
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _AvatarTap(
                      player: p,
                      onTap: () => openPlayerProfile(context, ref, p.id),
                    ),
                  ),
                )
                .toList(),
          )
        else
          _AvatarTap(
            player: players.first,
            onTap: () => openPlayerProfile(context, ref, players.first.id),
          ),
        const SizedBox(height: 8),
        Text(
          players.map((p) => p.name.split(' ').first).join(' / '),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

class _AvatarTap extends StatelessWidget {
  const _AvatarTap({required this.player, required this.onTap});

  final Player player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: UserAvatar(name: player.name, avatarUrl: player.avatarUrl, radius: 28),
    );
  }
}

class _FlatFallback extends ConsumerWidget {
  const _FlatFallback({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = <Player>[
      challenge.creator,
      ...challenge.participants.map((p) => p.user),
    ];
    return Column(
      children: all
          .map(
            (p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(name: p.name, avatarUrl: p.avatarUrl),
              title: Text(p.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openPlayerProfile(context, ref, p.id),
            ),
          )
          .toList(),
    );
  }
}
