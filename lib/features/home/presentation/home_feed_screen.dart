import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: FutureBuilder(
        future: ref.read(challengesRepositoryProvider).list(ChallengeListRole.publicNearby),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Carregando feed...');
          }
          final challenges = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Atividade recente', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Card(
                color: AppColors.card,
                child: ListTile(
                  leading: Icon(Icons.notifications_outlined, color: AppColors.lime),
                  title: Text('Em breve'),
                  subtitle: Text('Novidades dos jogadores que você segue.'),
                ),
              ),
              const SizedBox(height: 24),
              Text('Desafios públicos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (challenges.isEmpty)
                const EmptyState(
                  icon: Icons.public,
                  title: 'Nenhum desafio público por perto',
                  subtitle: 'Volte mais tarde ou crie um desafio público.',
                )
              else
                ...challenges.map(
                  (c) => Card(
                    color: AppColors.card,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.sports_tennis, color: AppColors.lime),
                      title: Text('${c.format.label} · ${c.type.label}'),
                      subtitle: Text(c.creator.name),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
