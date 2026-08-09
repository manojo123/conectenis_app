import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/notifications/data/notifications_repository.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;
  final Set<String> _readLocally = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(notificationsRepositoryProvider).list();
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool _isUnread(AppNotification n) =>
      n.readAt == null && !_readLocally.contains(n.id);

  int get _unreadCount => _items.where(_isUnread).length;

  Future<void> _markRead(AppNotification n) async {
    if (!_isUnread(n)) return;
    setState(() => _readLocally.add(n.id));
    try {
      await ref.read(notificationsRepositoryProvider).markRead(n.id);
      // The badge count lives on the auth user payload.
      await ref.read(authStateProvider.notifier).refreshUser();
    } catch (_) {
      // Keep the optimistic state; the next full load reconciles.
    }
  }

  Future<void> _markAllRead() async {
    final unread = _items.where(_isUnread).toList();
    if (unread.isEmpty) return;
    setState(() => _readLocally.addAll(unread.map((n) => n.id)));
    try {
      // No bulk endpoint yet (see docs/BACKEND_PROMPT_REDESIGN.md),
      // mark each notification individually.
      await Future.wait(
        unread.map(
          (n) => ref.read(notificationsRepositoryProvider).markRead(n.id),
        ),
      );
      await ref.read(authStateProvider.notifier).refreshUser();
      if (mounted) showToast(context, 'Todas marcadas como lidas.');
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    }
  }

  Future<void> _open(AppNotification n) async {
    final conversationId = n.conversationId;
    final challengeId = n.challengeId;
    final type = n.type.toLowerCase();
    await _markRead(n);
    if (!mounted) return;
    if (type.contains('group_chat') && conversationId != null) {
      context.push('/messages/$conversationId');
      return;
    }
    // ranking_up has no challenge_id - it points at the Rankings tab instead.
    if (type.contains('ranking')) {
      context.push('/ranking');
      return;
    }
    if (challengeId != null) context.push('/challenges/$challengeId');
  }

  (IconData, Color, Color) _visual(AppTokens t, String type) {
    final lower = type.toLowerCase();
    if (lower.contains('group_chat')) {
      return (Symbols.groups_rounded, t.tintAcc, t.accentText);
    }
    if (lower.contains('candidate')) {
      return (Symbols.group_add_rounded, t.tintInfo, t.info);
    }
    if (lower.contains('reminder') || lower.contains('scheduled')) {
      return (Symbols.event_rounded, t.tintWarn, t.warning);
    }
    if (lower.contains('evaluation') || lower.contains('result')) {
      return (Symbols.rate_review_rounded, t.tintErr, t.error);
    }
    if (lower.contains('ranking')) {
      return (Symbols.trending_up_rounded, t.tintSucc, t.success);
    }
    if (lower.contains('challenge')) {
      return (Symbols.sports_tennis_rounded, t.tintAcc, t.accentText);
    }
    return (Symbols.notifications_rounded, t.tintAcc, t.accentText);
  }

  String _title(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('group_chat')) return 'Novo chat de duplas';
    if (lower.contains('candidate')) return 'Novo candidato';
    if (lower.contains('reminder') || lower.contains('scheduled')) {
      return 'Partida agendada';
    }
    if (lower.contains('evaluation') || lower.contains('result')) {
      return 'Avaliação pendente';
    }
    if (lower.contains('ranking')) return 'Ranking atualizado';
    if (lower.contains('declined') || lower.contains('cancelled')) {
      return 'Desafio atualizado';
    }
    if (lower.contains('accepted')) return 'Desafio aceito';
    if (lower.contains('challenge')) return 'Novo desafio recebido';
    return 'Notificação';
  }

  String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final unread = _unreadCount;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleIconButton(
                    icon: Symbols.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificações',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unread > 0 ? '$unread não lidas' : 'Tudo em dia',
                          style: TextStyle(fontSize: 12.5, color: t.muted),
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _markAllRead,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Marcar lidas',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: t.accentText,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _items.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 80),
                                    EmptyState(
                                      icon: Symbols.notifications_rounded,
                                      title: 'Nenhuma notificação',
                                      subtitle:
                                          'Convites, candidaturas e resultados aparecem aqui.',
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(14, 2, 14,
                                      screenBottomInset(context) + 16),
                                  itemCount: _items.length,
                                  itemBuilder: (_, i) => _row(t, _items[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(AppTokens t, AppNotification n) {
    final (icon, tint, color) = _visual(t, n.type);
    final unread = _isUnread(n);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PressableScale(
        scale: 0.985,
        onTap: () => _open(n),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 21, fill: 1, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _title(n.type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w600,
                              color: t.text,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 7),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: t.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (n.message.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        n.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5, color: t.muted, height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _relativeTime(n.createdAt),
                      style: TextStyle(fontSize: 11, color: t.disabled),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
