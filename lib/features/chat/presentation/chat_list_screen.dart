import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/scrollable_fill.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  AsyncValue<List<Conversation>> _conversations = const AsyncLoading();
  bool _selectMode = false;
  final Set<int> _selectedIds = {};

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

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conversas'),
        content: Text('Excluir ${_selectedIds.length} conversa(s)? Elas sumirão só para você.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(chatRepositoryProvider);
      for (final id in _selectedIds) {
        await repo.deleteConversation(id);
      }
      _exitSelectMode();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : e.toString())),
        );
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode ? '${_selectedIds.length} selecionada(s)' : 'Mensagens'),
        leading: _selectMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectMode)
            : null,
        actions: [
          if (_selectMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _conversations.when(
          loading: () => const ScrollableFill(child: LoadingView()),
          error: (e, _) => ScrollableFill(
            child: ErrorView(
              message: _errorMessage(e),
              onRetry: _load,
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const ScrollableFill(
                child: EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'Nenhuma conversa',
                  subtitle: 'Envie uma mensagem a partir da busca de jogadores.',
                ),
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: screenBottomInset(context)),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                final selected = _selectedIds.contains(c.id);
                return ListTile(
                  leading: _selectMode
                      ? Checkbox(
                          value: selected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedIds.add(c.id);
                              } else {
                                _selectedIds.remove(c.id);
                              }
                            });
                          },
                        )
                      : UserAvatar(name: c.otherUserName, avatarUrl: c.otherAvatarUrl),
                  title: Text(c.otherUserName),
                  subtitle: Text(c.lastMessage ?? 'Nova conversa'),
                  trailing: c.updatedAt != null
                      ? Text(DateFormat.Hm().format(c.updatedAt!), style: const TextStyle(fontSize: 12))
                      : null,
                  onTap: () {
                    if (_selectMode) {
                      setState(() {
                        if (selected) {
                          _selectedIds.remove(c.id);
                        } else {
                          _selectedIds.add(c.id);
                        }
                      });
                    } else {
                      openChatThread(context, c);
                    }
                  },
                  onLongPress: () {
                    if (!_selectMode) {
                      setState(() {
                        _selectMode = true;
                        _selectedIds.add(c.id);
                      });
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
