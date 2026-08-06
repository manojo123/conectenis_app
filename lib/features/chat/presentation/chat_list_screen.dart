import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/app/nav_badges.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/scrollable_fill.dart';
import 'package:conectenis_app/shared/widgets/theme_toggle_button.dart';
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
      if (mounted) bumpConversationsRefresh(ref);
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
        content: Text(
            'Excluir ${_selectedIds.length} conversa(s)? Elas sumirão só para você.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
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
        showToast(context, e is ApiException ? e.message : e.toString());
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  String _timeLabel(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    if (day == today) return DateFormat.Hm().format(time);
    if (day == today.subtract(const Duration(days: 1))) return 'Ontem';
    if (now.difference(time).inDays < 7) {
      return DateFormat.E('pt_BR').format(time);
    }
    return DateFormat('dd/MM').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  if (_selectMode) ...[
                    CircleIconButton(
                      icon: Symbols.close_rounded,
                      onTap: _exitSelectMode,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} selecionada(s)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: t.text,
                        ),
                      ),
                    ),
                    CircleIconButton(
                      icon: Symbols.delete_rounded,
                      color: _selectedIds.isEmpty ? t.disabled : t.error,
                      onTap: _selectedIds.isEmpty ? null : _deleteSelected,
                      tooltip: 'Excluir',
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        'Mensagens',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: t.text,
                        ),
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
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
                          icon: Symbols.chat_bubble_rounded,
                          title: 'Nenhuma conversa',
                          subtitle:
                              'As conversas começam quando um desafio é aceito — ou toque em um jogador no mapa.',
                        ),
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                          14, 2, 14, screenBottomInset(context) + 8),
                      itemCount: list.length + 1,
                      itemBuilder: (_, i) {
                        if (i == list.length) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(30, 20, 30, 8),
                            child: Text(
                              'As conversas começam quando um desafio é aceito — ou toque em um jogador no mapa.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: t.disabled,
                                height: 1.6,
                              ),
                            ),
                          );
                        }
                        return _conversationCard(t, list[i]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversationCard(AppTokens t, Conversation c) {
    final selected = _selectedIds.contains(c.id);
    final unread = c.unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PressableScale(
        scale: 0.985,
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
        child: GestureDetector(
          onLongPress: () {
            if (!_selectMode) {
              setState(() {
                _selectMode = true;
                _selectedIds.add(c.id);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.surface,
              border: Border.all(
                color: selected ? t.accent : t.border,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    UserAvatar(
                      name: c.otherUserName,
                      avatarUrl: c.otherAvatarUrl,
                      userId: c.otherUserId,
                      radius: 26,
                    ),
                    if (_selectMode)
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? t.accent.withValues(alpha: 0.75)
                                : Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            selected
                                ? Symbols.check_rounded
                                : Symbols.circle_rounded,
                            size: 22,
                            weight: 700,
                            color:
                                selected ? t.onAccent : Colors.white70,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              c.otherUserName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: t.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeLabel(c.updatedAt),
                            style:
                                TextStyle(fontSize: 11.5, color: t.disabled),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.lastMessage ?? 'Nova conversa',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: unread ? t.text : t.muted,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 19),
                              height: 19,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: t.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${c.unreadCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: t.onAccent,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
