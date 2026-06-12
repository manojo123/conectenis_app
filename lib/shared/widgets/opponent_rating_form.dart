import 'package:flutter/material.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/widgets/star_rating_input.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class OpponentRatingInput {
  int punctualityStars = 0;
  int fairPlayStars = 0;
  int communicationStars = 0;
  final TextEditingController commentController = TextEditingController();

  bool get isComplete =>
      punctualityStars > 0 && fairPlayStars > 0 && communicationStars > 0;

  void dispose() => commentController.dispose();
}

class OpponentRatingForm extends StatelessWidget {
  const OpponentRatingForm({
    super.key,
    required this.player,
    required this.rating,
    required this.onChanged,
  });

  final Player? player;
  final OpponentRatingInput rating;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  name: player?.name ?? '',
                  avatarUrl: player?.avatarUrl,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    player?.name ?? 'Jogador',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Pontualidade'),
            StarRatingInput(
              value: rating.punctualityStars,
              onChanged: (v) {
                rating.punctualityStars = v;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            const Text('Fair Play (Espírito Esportivo)'),
            StarRatingInput(
              value: rating.fairPlayStars,
              onChanged: (v) {
                rating.fairPlayStars = v;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            const Text('Comunicação'),
            StarRatingInput(
              value: rating.communicationStars,
              onChanged: (v) {
                rating.communicationStars = v;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: rating.commentController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Comentário (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
