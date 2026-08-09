import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/app/nav_badges.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/data/delete_message_scope.dart';
import 'package:conectenis_app/features/chat/services/reverb_service.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/chat_timeline_entry.dart';
import 'package:conectenis_app/shared/models/message.dart';
import 'package:conectenis_app/shared/utils/player_navigation.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/chat_challenge_panel.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.conversationId,
    this.otherUserId,
    this.otherUserName,
    this.otherAvatarUrl,
  });

  final int conversationId;
  final int? otherUserId;
  final String? otherUserName;
  final String? otherAvatarUrl;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatTimelineEntry> _timeline = [];
  bool _loading = true;
  String? _error;
  String? _peerName;
  String? _peerAvatarUrl;
  int? _peerUserId;
  late final ChatRepository _chatRepository;
  late final ReverbService _reverbService;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _chatRepository = ref.read(chatRepositoryProvider);
    _reverbService = ref.read(reverbServiceProvider);
    _peerName = widget.otherUserName;
    _peerAvatarUrl = widget.otherAvatarUrl;
    _peerUserId = widget.otherUserId;
    _load();
    _markRead();
    _subscribeReverb();
    // Reverb is disabled in this deployment (no realtime push), so fall back
    // to light polling to keep the thread reasonably live.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _silentRefresh());
  }

  Future<void> _markRead() async {
    try {
      await _chatRepository.markRead(widget.conversationId);
      bumpConversationsRefresh(ref);
    } catch (_) {
      // Best-effort: an unread badge that fails to clear once isn't worth surfacing.
    }
  }

  Future<void> _silentRefresh() async {
    if (!mounted || _loading) return;
    try {
      final userId = ref.read(authStateProvider).value?.id;
      final list = await _chatRepository.timeline(
        widget.conversationId,
        currentUserId: userId,
      );
      if (!mounted || list.length == _timeline.length) return;
      setState(() => _timeline = list);
    } catch (_) {
      // Silent refresh: leave the current timeline as-is on failure.
    }
  }

  Future<void> _subscribeReverb() async {
    if (!Env.reverbEnabled) return;
    await _reverbService.subscribeToConversation(
      conversationId: widget.conversationId,
      onMessage: (_) {
        if (!mounted) return;
        _load();
      },
    );
  }

  Future<void> _loadPeerInfo() async {
    if (_peerName != null && _peerName!.isNotEmpty && _peerUserId != null) return;
    final conversation =
        await _chatRepository.conversationById(widget.conversationId);
    if (!mounted || conversation == null) return;
    setState(() {
      _peerName = conversation.otherUserName;
      _peerAvatarUrl = conversation.otherAvatarUrl;
      _peerUserId = conversation.otherUserId;
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = ref.read(authStateProvider).value?.id;
      final list = await _chatRepository.timeline(
        widget.conversationId,
        currentUserId: userId,
      );
      if (!mounted) return;
      setState(() {
        _timeline = list;
        _loading = false;
      });
      await _loadPeerInfo();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;

    _controller.clear();
    try {
      final msg = await _chatRepository.send(
        conversationId: widget.conversationId,
        userId: userId,
        body: body,
      );
      if (!mounted) return;
      setState(() => _timeline = [..._timeline, ChatMessageTimelineEntry(msg)]);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(context, e is ApiException ? e.message : e.toString());
      }
    }
  }

  void _openProfile() {
    final id = _peerUserId;
    if (id == null) return;
    openPlayerProfile(context, ref, id);
  }

  Future<void> _confirmDeleteMessage(Message message) async {
    final scope = await showModalBottomSheet<DeleteMessageScope>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Apagar para mim'),
              onTap: () => Navigator.pop(ctx, DeleteMessageScope.forMe),
            ),
            if (message.isMine)
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('Apagar para todos'),
                onTap: () => Navigator.pop(ctx, DeleteMessageScope.forEveryone),
              ),
          ],
        ),
      ),
    );
    if (scope == null || !mounted) return;

    try {
      await _chatRepository.deleteMessage(message.id, scope: scope);
      if (!mounted) return;
      setState(() {
        _timeline = _timeline.where((entry) {
          if (entry is ChatMessageTimelineEntry) {
            return entry.message.id != message.id;
          }
          return true;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        showToast(context, e is ApiException ? e.message : e.toString());
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _reverbService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final title = _peerName?.isNotEmpty == true ? _peerName! : 'Chat';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header: back + tappable identity row.
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.border)),
              ),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Symbols.arrow_back_rounded,
                    size: 38,
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/messages'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _peerUserId != null ? _openProfile : null,
                      child: Row(
                        children: [
                          UserAvatar(
                            name: title,
                            avatarUrl: _peerAvatarUrl,
                            userId: _peerUserId,
                            radius: 21,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: t.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _timeline.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhuma mensagem ainda.\nDiga olá para $title.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: t.muted,
                                  height: 1.6,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(
                                  14, 14, 14, screenBottomInset(context)),
                              itemCount: _timeline.length,
                              itemBuilder: (_, i) {
                                final entry = _timeline[i];
                                if (entry is ChatChallengeTimelineEntry) {
                                  return ChatChallengePanel(event: entry.event);
                                }
                                final m =
                                    (entry as ChatMessageTimelineEntry).message;
                                return _bubble(t, m);
                              },
                            ),
            ),
            _composer(t),
          ],
        ),
      ),
    );
  }

  Widget _bubble(AppTokens t, Message m) {
    final mine = m.isMine;
    return GestureDetector(
      onLongPress: () => _confirmDeleteMessage(m),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: mine ? t.accent : t.surface2,
              border: mine ? null : Border.all(color: t.border),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 6),
                bottomRight: Radius.circular(mine ? 6 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: mine ? FontWeight.w600 : FontWeight.w400,
                    color: mine ? t.onAccent : t.text,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    DateFormat.Hm().format(m.createdAt),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mine
                          ? t.onAccent.withValues(alpha: 0.55)
                          : t.disabled,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _composer(AppTokens t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.inputBg,
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Mensagem…',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  hintStyle: TextStyle(fontSize: 14, color: t.muted),
                ),
                style: TextStyle(fontSize: 14, color: t.text),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasText ? t.accent : t.disabledBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Symbols.send_rounded,
                    size: 20,
                    fill: 1,
                    color: hasText ? t.onAccent : t.disabled,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

void openChatThread(BuildContext context, Conversation conversation) {
  context.push('/messages/${conversation.id}', extra: conversation);
}
