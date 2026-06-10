import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _challengesTabIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: navigationShell,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: navigationShell.goBranch,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_tennis_outlined),
              selectedIcon: Icon(Icons.sports_tennis),
              label: 'Desafios',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard),
              label: 'Ranking',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Mensagens',
            ),
          ],
        ),
      ),
      floatingActionButton: navigationShell.currentIndex == _challengesTabIndex
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton.extended(
                  onPressed: () => _showCreateChallengeMenu(context),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  icon: const Icon(Icons.add),
                  label: const Text('Desafio'),
                ),
              ),
            )
          : null,
    );
  }

  void _showCreateChallengeMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person, color: Theme.of(ctx).colorScheme.primary),
              title: const Text('Desafio direto'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/challenges/new/direct');
              },
            ),
            ListTile(
              leading: Icon(Icons.public, color: Theme.of(ctx).colorScheme.primary),
              title: const Text('Desafio público'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/challenges/new/public');
              },
            ),
          ],
        ),
      ),
    );
  }
}
