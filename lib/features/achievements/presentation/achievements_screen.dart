import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conquistas')),
      body: const Center(
        child: Text(
          'Em breve',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
        ),
      ),
    );
  }
}
