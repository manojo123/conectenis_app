import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conquistas')),
      body: Center(
        child: Text(
          'Em breve',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
