import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

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

        return Scaffold(
          appBar: AppBar(title: Text(player.name)),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 48,
                  child: Text(player.name[0], style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 24),
                _InfoRow('Nível', player.skillLevel.label),
                _InfoRow('Idade', '${player.age ?? '?'} anos'),
                _InfoRow('Estilo', player.playStyle.label),
                if (player.distanceKm != null)
                  _InfoRow('Distância', '${player.distanceKm!.toStringAsFixed(1)} km'),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => context.push('/invitations/new?playerId=${player.id}'),
                  icon: const Icon(Icons.sports_tennis),
                  label: const Text('Convidar para jogar'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final conv = await ref.read(chatRepositoryProvider).start(
                          player.id,
                          player.name,
                        );
                    if (context.mounted) context.push('/chat/${conv.id}');
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Enviar mensagem'),
                ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
