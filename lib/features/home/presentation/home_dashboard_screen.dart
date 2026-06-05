import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PlaceholderCard(
            icon: Icons.sports_tennis,
            title: 'Desafios ativos',
            subtitle: 'Em breve: resumo dos seus desafios em andamento.',
          ),
          _PlaceholderCard(
            icon: Icons.leaderboard,
            title: 'Ranking',
            subtitle: 'Em breve: sua posição e destaques da semana.',
          ),
          _PlaceholderCard(
            icon: Icons.history,
            title: 'Últimas partidas',
            subtitle: 'Em breve: histórico recente de jogos.',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.lime),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
