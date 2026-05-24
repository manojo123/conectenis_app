import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/profile/providers/profile_feedback_provider.dart';
import 'package:conectenis_app/shared/utils/date_of_birth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(profileUpdatedNoticeProvider, (previous, next) {
      if (next && mounted) {
        ref.read(profileUpdatedNoticeProvider.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso.')),
        );
      }
    });

    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          Center(
            child: UserAvatar(
              name: user?.name ?? '',
              avatarUrl: user?.avatarUrl,
              radius: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(user?.name ?? '', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          Text(user?.email ?? '', textAlign: TextAlign.center),
          if (user != null) ...[
            const SizedBox(height: 8),
            Text(
              'NTRP ${user.ntrpRating.toStringAsFixed(1)} · ${formatDateOfBirth(user.dateOfBirth)}',
              textAlign: TextAlign.center,
            ),
            if (user.age != null)
              Text('${user.age} anos', textAlign: TextAlign.center),
            if (user.gender != null) Text(user.gender!.label, textAlign: TextAlign.center),
            if (user.city != null) Text('${user.city}, ${user.state}', textAlign: TextAlign.center),
            if (user.profession != null && user.profession!.isNotEmpty)
              Text(user.profession!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Buscar jogadores'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/players-search'),
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
