import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/chat/data/chat_repository.dart';
import 'package:conectenis_app/features/chat/data/delete_message_scope.dart';
import 'package:conectenis_app/features/chat/services/reverb_service.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/message.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
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
  List<Message> _messages = [];
  bool _loading = true;
  String? _error;
  String? _peerName;
  String? _peerAvatarUrl;
  int? _peerUserId;

  @override
  void initState() {
    super.initState();
    _peerName = widget.otherUserName;
    _peerAvatarUrl = widget.otherAvatarUrl;
    _peerUserId = widget.otherUserId;
    _load();
    _subscribeReverb();
  }

  Future<void> _subscribeReverb() async {
    if (!Env.reverbEnabled) return;
    await ref.read(reverbServiceProvider).subscribeToConversation(
          conversationId: widget.conversationId,
          onMessage: (_) => _load(),
        );
  }

  Future<void> _loadPeerInfo() async {
    if (_peerName != null && _peerName!.isNotEmpty && _peerUserId != null) return;
    final conversation =
        await ref.read(chatRepositoryProvider).conversationById(widget.conversationId);
    if (!mounted || conversation == null) return;
    setState(() {
      _peerName = conversation.otherUserName;
      _peerAvatarUrl = conversation.otherAvatarUrl;
      _peerUserId = conversation.otherUserId;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = ref.read(authStateProvider).value?.id;
      final list = await ref.read(chatRepositoryProvider).messages(
            widget.conversationId,
            currentUserId: userId,
          );
      if (mounted) {
        setState(() {
          _messages = list;
          _loading = false;
        });
      }
      await _loadPeerInfo();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is ApiException ? e.message : e.toString();
        });
      }
    }
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;

    _controller.clear();
    try {
      final msg = await ref.read(chatRepositoryProvider).send(
            conversationId: widget.conversationId,
            userId: userId,
            body: body,
          );
      setState(() => _messages = [..._messages, msg]);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : e.toString())),
        );
      }
    }
  }

  void _openProfile() {
    final id = _peerUserId;
    if (id == null) return;
    context.push('/players/$id');
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
      await ref.read(chatRepositoryProvider).deleteMessage(message.id, scope: scope);
      setState(() => _messages = _messages.where((m) => m.id != message.id).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : e.toString())),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    ref.read(reverbServiceProvider).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _peerName?.isNotEmpty == true ? _peerName! : 'Chat';

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _peerUserId != null ? _openProfile : null,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              UserAvatar(
                name: title,
                avatarUrl: _peerAvatarUrl,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/messages'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhuma mensagem ainda.\nDiga olá para $title.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(12, 12, 12, screenBottomInset(context)),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final m = _messages[i];
                              return GestureDetector(
                                onLongPress: () => _confirmDeleteMessage(m),
                                child: Align(
                                  alignment:
                                      m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m.isMine ? AppColors.navy : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.body,
                                          style: TextStyle(
                                            color: m.isMine ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          DateFormat.Hm().format(m.createdAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: m.isMine ? Colors.white70 : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Mensagem...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void openChatThread(BuildContext context, Conversation conversation) {
  context.push('/messages/${conversation.id}', extra: conversation);
}
