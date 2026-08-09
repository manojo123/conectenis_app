import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:conectenis_app/shared/widgets/challenge_status_chip.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';
import 'package:conectenis_app/shared/widgets/status_badge.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

/// Prototype challenge card: avatar header, badge row, info rows, quoted
/// message, score chip and inline context actions supplied by the wall.
class ChallengeMuralCard extends StatelessWidget {
  const ChallengeMuralCard({
    super.key,
    required this.challenge,
    this.highlightDirect = false,
    this.actions = const [],
    this.currentUserId,
  });

  final Challenge challenge;

  /// Lime border for direct invites awaiting the user (prototype "Recebidos").
  final bool highlightDirect;

  /// Inline action buttons (Aceitar/Recusar/Candidatar-se/…) built by the wall.
  final List<Widget> actions;

  final int? currentUserId;

  bool get _isMine =>
      currentUserId != null && challenge.creator.id == currentUserId;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final df = DateFormat('EEE, dd/MM · HH:mm', 'pt_BR');
    final c = challenge;
    final isPublic = c.type == ChallengeType.public;

    final headerName =
        _isMine && isPublic ? 'Seu desafio público' : c.creator.name;
    final headerSub = isPublic
        ? (_isMine
            ? 'Aberto a candidaturas'
            : 'NTRP ${c.minNtrp != null ? ntrpValueLabel(c.minNtrp!) : '-'} – ${c.maxNtrp != null ? ntrpValueLabel(c.maxNtrp!) : '-'}')
        : 'NTRP ${ntrpValueLabel(c.creator.ntrpRating)}'
            '${c.creator.locationLabel.isNotEmpty ? ' · ${c.creator.locationLabel}' : ''}';

    final scoreLabel = c.result?.scoreLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressableScale(
        scale: 0.99,
        onTap: () => context.push('/challenges/${c.id}'),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: highlightDirect
                ? Color.alphaBlend(t.tintAcc.withValues(alpha: 0.06), t.surface)
                : t.surface,
            border: Border.all(
              color: highlightDirect ? t.accent : t.border,
              width: highlightDirect ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    name: c.creator.name,
                    avatarUrl: c.creator.avatarUrl,
                    hasCustomAvatar: c.creator.hasCustomAvatar,
                    userId: c.creator.id,
                    radius: 23,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          headerSub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: t.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  isPublic
                      ? const StatusBadge.accent('Público')
                      : const StatusBadge.info('Direto'),
                  StatusBadge(c.format.label),
                  ChallengeStatusChip(status: c.status),
                ],
              ),
              const SizedBox(height: 11),
              _infoRow(t, Symbols.schedule_rounded, df.format(c.scheduledStart)),
              const SizedBox(height: 6),
              _infoRow(
                t,
                Symbols.location_on_rounded,
                c.place != null
                    ? '${c.place!.name}'
                        '${c.distanceKm != null ? ' · ${c.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km' : ''}'
                    : 'Local em aberto',
              ),
              if (isPublic && !_isMine && c.minNtrp != null) ...[
                const SizedBox(height: 6),
                _infoRow(
                  t,
                  Symbols.star_rounded,
                  'Nível ${ntrpValueLabel(c.minNtrp!)} – ${c.maxNtrp != null ? ntrpValueLabel(c.maxNtrp!) : '-'}',
                ),
              ],
              if (isPublic && _isMine) ...[
                const SizedBox(height: 6),
                _infoRow(
                  t,
                  Symbols.group_rounded,
                  c.candidatesCount == 1
                      ? '1 candidato'
                      : '${c.candidatesCount} candidatos',
                ),
              ],
              if ((c.message ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: t.accent, width: 2.5),
                    ),
                  ),
                  child: Text(
                    '“${c.message!}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: t.muted,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (scoreLabel != null && scoreLabel.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    scoreLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: t.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 13),
                Row(
                  children: [
                    for (final (i, action) in actions.indexed) ...[
                      if (i > 0) const SizedBox(width: 9),
                      Expanded(child: action),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(AppTokens t, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: t.disabled),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: t.muted),
          ),
        ),
      ],
    );
  }
}

/// Small inline action button used inside challenge cards.
class CardActionButton extends StatelessWidget {
  const CardActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = CardActionKind.outline,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final CardActionKind kind;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final enabled = onTap != null && !loading;
    final (bg, fg, border, shadow) = switch (kind) {
      CardActionKind.primary => (t.accent, t.onAccent, Colors.transparent, t.glow),
      CardActionKind.outline => (
          Colors.transparent,
          t.text,
          t.border,
          const <BoxShadow>[]
        ),
      CardActionKind.accentOutline => (
          Colors.transparent,
          t.accentText,
          t.accent,
          const <BoxShadow>[]
        ),
      CardActionKind.danger => (
          Colors.transparent,
          t.error,
          t.error.withValues(alpha: 0.5),
          const <BoxShadow>[]
        ),
      CardActionKind.disabled => (
          t.disabledBg,
          t.disabled,
          Colors.transparent,
          const <BoxShadow>[]
        ),
    };

    return PressableScale(
      scale: 0.97,
      enabled: enabled,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled ? shadow : null,
        ),
        child: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
      ),
    );
  }
}

enum CardActionKind { primary, outline, accentOutline, danger, disabled }
