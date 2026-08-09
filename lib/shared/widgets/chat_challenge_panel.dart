import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/chat_timeline_entry.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/challenge_status_chip.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';

/// Prototype in-thread challenge card: lime-bordered bubble with the
/// DESAFIO DE TÊNIS header. When the challenge is a pending invite for the
/// current user it offers inline Aceitar/Recusar (prototype behavior).
class ChatChallengePanel extends ConsumerStatefulWidget {
  const ChatChallengePanel({super.key, required this.event});

  final ChatChallengeEvent event;

  @override
  ConsumerState<ChatChallengePanel> createState() => _ChatChallengePanelState();
}

class _ChatChallengePanelState extends ConsumerState<ChatChallengePanel> {
  Challenge? _challenge;
  ChallengeStatus? _statusOverride;
  bool _busy = false;

  ChallengeStatus get _status =>
      _statusOverride ?? _challenge?.status ?? widget.event.status;

  @override
  void initState() {
    super.initState();
    // Role isn't carried on the chat event - fetch once to know whether
    // the inline Aceitar/Recusar actions apply to this user.
    if (widget.event.status == ChallengeStatus.pendingAcceptance) {
      _loadChallenge();
    }
  }

  Future<void> _loadChallenge() async {
    try {
      final c = await ref
          .read(challengesRepositoryProvider)
          .byId(widget.event.challengeId);
      if (mounted) setState(() => _challenge = c);
    } catch (_) {
      // Card falls back to link-only behavior.
    }
  }

  bool get _canRespond =>
      _challenge != null &&
      _challenge!.role == 'received' &&
      _status == ChallengeStatus.pendingAcceptance;

  Future<void> _respond({required bool accept}) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(challengesRepositoryProvider);
      final updated = accept
          ? await repo.accept(widget.event.challengeId)
          : await repo.decline(widget.event.challengeId);
      bumpChallengesRefresh(ref);
      if (mounted) {
        setState(() => _statusOverride = updated.status);
        showToast(
          context,
          accept ? 'Desafio aceito! Partida agendada.' : 'Desafio recusado.',
        );
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: GestureDetector(
          onTap: () => context.push('/challenges/${widget.event.challengeId}'),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.surface,
              border: Border.all(color: t.accent, width: 1.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Symbols.sports_tennis_rounded,
                        size: 19, fill: 1, color: t.accentText),
                    const SizedBox(width: 8),
                    Text(
                      'DESAFIO DE TÊNIS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: t.accentText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  widget.event.summary ?? 'Desafio de tênis',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (_canRespond)
                  Row(
                    children: [
                      Expanded(
                        flex: 100,
                        child: PressableScale(
                          scale: 0.97,
                          enabled: !_busy,
                          onTap: _busy ? null : () => _respond(accept: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: t.error.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Recusar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: t.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 130,
                        child: PressableScale(
                          scale: 0.97,
                          enabled: !_busy,
                          onTap: _busy ? null : () => _respond(accept: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: t.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _busy
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: t.onAccent),
                                  )
                                : Text(
                                    'Aceitar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: t.onAccent,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ChallengeStatusChip(status: _status),
                      Text(
                        'Ver detalhes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: t.accentText,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
