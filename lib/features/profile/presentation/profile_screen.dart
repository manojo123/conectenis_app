import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(
              (user?.name.isNotEmpty == true) ? user!.name[0] : '?',
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(user?.email ?? '', textAlign: TextAlign.center),
          if (user?.age != null) ...[
            const SizedBox(height: 8),
            Text(
              '${user!.skillLevel.label} · ${user.age} anos',
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Mensagens'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/chat'),
          ),
          ListTile(
            leading: const Icon(Icons.sports_score),
            title: const Text('Registrar partida'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/matches/log'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Histórico e rivais'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/matches/history'),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
