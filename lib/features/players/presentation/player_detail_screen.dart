import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:conectenis_app/shared/widgets/app_card.dart';
import 'package:conectenis_app/shared/widgets/bottom_action_bar.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/full_screen_image_viewer.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/ntrp_stars.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/stat_tile.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({super.key, required this.playerId});

  final int playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(playersRepositoryProvider).byId(playerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: LoadingView());
        }
        final player = snapshot.data;
        if (player == null) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const ScreenHeader(title: 'Jogador'),
                  const Expanded(
                    child: ErrorView(message: 'Jogador não encontrado'),
                  ),
                ],
              ),
            ),
          );
        }
        return _PlayerProfileBody(player: player);
      },
    );
  }
}

class _PlayerProfileBody extends ConsumerWidget {
  const _PlayerProfileBody({required this.player});

  final Player player;

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final conv =
        await ref.read(chatRepositoryProvider).start(player.id, player.name);
    if (!context.mounted) return;
    openChatThread(
      context,
      Conversation(
        id: conv.id,
        otherUserId: conv.otherUserId,
        otherUserName: conv.otherUserName,
        otherAvatarUrl: player.avatarUrl ?? conv.otherAvatarUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final heroTag = 'player-avatar-${player.id}';
    final dims = player.ratingDimensions;

    final subParts = <String>[
      if (player.age != null) '${player.age} anos',
      if ((player.profession ?? '').isNotEmpty) player.profession!,
    ];
    final locationParts = <String>[
      if (player.locationLabel.isNotEmpty) player.locationLabel,
      if (player.distanceKm != null)
        'a ${player.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Tinted gradient header with back button + identity block.
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [t.tintAcc, t.tintAcc.withValues(alpha: 0)],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.viewPaddingOf(context).top + 14,
                    left: 16,
                    right: 16,
                    bottom: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleIconButton(
                            icon: Symbols.arrow_back_rounded,
                            onTap: () => context.pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => showFullScreenImage(
                          context,
                          imageUrl: player.avatarUrl,
                          heroTag: heroTag,
                        ),
                        child: Hero(
                          tag: heroTag,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: t.accent, width: 3),
                            ),
                            child: UserAvatar(
                              name: player.name,
                              avatarUrl: player.avatarUrl,
                              hasCustomAvatar: player.hasCustomAvatar,
                              userId: player.id,
                              radius: 47,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        player.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: t.text,
                        ),
                      ),
                      if (subParts.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subParts.join(' · '),
                          style: TextStyle(fontSize: 13, color: t.muted),
                        ),
                      ],
                      if (locationParts.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Symbols.location_on_rounded,
                                size: 15, fill: 1, color: t.accentText),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                locationParts.join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(fontSize: 12.5, color: t.muted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      ntrpValueLabel(player.ntrpRating),
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: t.accentText,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'NTRP',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: t.muted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  ntrpLevelName(player.ntrpRating),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: t.muted,
                                  ),
                                ),
                              ],
                            ),
                            NtrpStars(value: player.ntrpRating, size: 24),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              dense: true,
                              value: '${player.matchesPlayed ?? 0}',
                              label: 'Partidas',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatTile(
                              dense: true,
                              value: '${player.challengesWon ?? 0}',
                              label: 'Vitórias',
                              valueColor: t.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatTile(
                              dense: true,
                              value: player.averageRating != null
                                  ? player.averageRating!
                                      .toStringAsFixed(1)
                                      .replaceAll('.', ',')
                                  : '-',
                              label: 'Avaliação',
                              valueColor: t.warning,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatTile(
                              dense: true,
                              value: '${player.reviewsCount ?? 0}',
                              label: 'Reviews',
                              valueColor: t.accentText,
                            ),
                          ),
                        ],
                      ),
                      if (dims != null &&
                          (dims.punctuality != null ||
                              dims.fairPlay != null ||
                              dims.communication != null)) ...[
                        const SizedBox(height: 10),
                        AppCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 6),
                          child: Column(
                            children: [
                              if (dims.punctuality != null)
                                _DimensionRow(
                                  label: 'Pontualidade',
                                  value: dims.punctuality!,
                                  divider: dims.fairPlay != null ||
                                      dims.communication != null,
                                ),
                              if (dims.fairPlay != null)
                                _DimensionRow(
                                  label: 'Fair play',
                                  value: dims.fairPlay!,
                                  divider: dims.communication != null,
                                ),
                              if (dims.communication != null)
                                _DimensionRow(
                                  label: 'Comunicação',
                                  value: dims.communication!,
                                  divider: false,
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (player.recentReviews.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 9),
                          child: Text(
                            'Comentários da comunidade',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: t.text,
                            ),
                          ),
                        ),
                        ...player.recentReviews.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              radius: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          r.author,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: t.text,
                                          ),
                                        ),
                                      ),
                                      NtrpStars(
                                        value: r.stars.toDouble(),
                                        size: 15,
                                        color: t.warning,
                                      ),
                                    ],
                                  ),
                                  if (r.comment.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      r.comment,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: t.muted,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            Expanded(
              flex: 100,
              child: LimeButton(
                label: 'Mensagem',
                outlined: true,
                icon: Symbols.chat_bubble_rounded,
                onPressed: () => _openChat(context, ref),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 125,
              child: LimeButton(
                label: 'Desafiar',
                glow: true,
                icon: Symbols.sports_tennis_rounded,
                onPressed: () =>
                    context.push('/challenges/new/direct?playerId=${player.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  const _DimensionRow({
    required this.label,
    required this.value,
    required this.divider,
  });

  final String label;
  final double value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.muted,
                  ),
                ),
              ),
              NtrpStars(value: value, size: 16, color: t.warning),
              const SizedBox(width: 8),
              Text(
                value.toStringAsFixed(1).replaceAll('.', ','),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: t.text,
                ),
              ),
            ],
          ),
        ),
        if (divider) Divider(height: 1, color: t.border),
      ],
    );
  }
}
