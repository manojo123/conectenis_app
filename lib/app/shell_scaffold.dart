import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

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
              icon: Icon(Icons.menu),
              selectedIcon: Icon(Icons.menu_open),
              label: 'Menu',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Mensagens',
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
          ],
        ),
      ),
      floatingActionButton: navigationShell.currentIndex == 3
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton.extended(
                  onPressed: () => _showCreateChallengeMenu(context),
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.background,
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
      backgroundColor: AppColors.card,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.lime),
              title: const Text('Desafio direto'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/challenges/new/direct');
              },
            ),
            ListTile(
              leading: const Icon(Icons.public, color: AppColors.lime),
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
