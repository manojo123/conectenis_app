import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  AsyncValue _conversations = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _conversations = const AsyncLoading());
    try {
      final list = await ref.read(chatRepositoryProvider).conversations();
      setState(() => _conversations = AsyncData(list));
    } catch (e, st) {
      setState(() => _conversations = AsyncError(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _conversations.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: _load),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'Nenhuma conversa',
                subtitle: 'Envie uma mensagem a partir do perfil de um jogador.',
              );
            }
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(c.otherUserName[0])),
                  title: Text(c.otherUserName),
                  subtitle: Text(c.lastMessage ?? 'Nova conversa'),
                  trailing: c.updatedAt != null
                      ? Text(DateFormat.Hm().format(c.updatedAt!), style: const TextStyle(fontSize: 12))
                      : null,
                  onTap: () => context.push('/chat/${c.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
