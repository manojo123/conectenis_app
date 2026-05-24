import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/full_screen_image_viewer.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
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
            appBar: AppBar(),
            body: const ErrorView(message: 'Jogador não encontrado'),
          );
        }

        final heroTag = 'player-avatar-${player.id}';

        return Scaffold(
          appBar: AppBar(title: Text(player.name)),
          body: ListView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => showFullScreenImage(
                      context,
                      imageUrl: player.avatarUrl,
                      heroTag: heroTag,
                    ),
                    child: Hero(
                      tag: heroTag,
                      child: UserAvatar(
                        name: player.name,
                        avatarUrl: player.avatarUrl,
                        radius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.name, style: Theme.of(context).textTheme.headlineSmall),
                        Text('NTRP ${player.ntrpRating.toStringAsFixed(1)}'),
                        if (player.profession != null) Text('Profissão: ${player.profession}'),
                        Text('Idade: ${player.age ?? '?'}'),
                        if (player.locationLabel.isNotEmpty) Text(player.locationLabel),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (player.matchesPlayed != null)
                _InfoRow('Partidas pelo app', '${player.matchesPlayed}'),
              if (player.challengesWon != null)
                _InfoRow('Desafios vencidos', '${player.challengesWon}'),
              if (player.averageRating != null)
                _InfoRow('Avaliação', '${player.averageRating} (${player.reviewsCount ?? 0})'),
              ...player.recentReviews.map(
                (r) => ListTile(
                  dense: true,
                  title: Text(r.author),
                  subtitle: Text(r.comment),
                  trailing: Text('★' * r.stars),
                ),
              ),
              const SizedBox(height: 24),
              LimeButton(
                label: 'Desafiar',
                icon: Icons.sports_tennis,
                onPressed: () => context.push('/challenges/new/direct?playerId=${player.id}'),
              ),
              const SizedBox(height: 8),
              LimeButton(
                label: 'Mensagem',
                outlined: true,
                icon: Icons.chat,
                onPressed: () async {
                  final conv = await ref.read(chatRepositoryProvider).start(
                        player.id,
                        player.name,
                      );
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
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
