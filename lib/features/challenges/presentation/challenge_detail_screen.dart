import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/utils/date_time_format.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:conectenis_app/shared/widgets/app_card.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/challenge_participants_versus.dart';
import 'package:conectenis_app/shared/widgets/challenge_result_section.dart';
import 'package:conectenis_app/shared/widgets/challenge_status_chip.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/info_row.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/static_place_map.dart';
import 'package:conectenis_app/shared/widgets/status_badge.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  ConsumerState<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen> {
  Challenge? _challenge;
  bool _loading = true;
  String? _error;
  bool _busy = false;

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
      final c = await ref.read(challengesRepositoryProvider).byId(widget.challengeId);
      setState(() {
        _challenge = c;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      bumpChallengesRefresh(ref);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _approveResult() {
    context.push('/challenges/${widget.challengeId}/approve-evaluation');
  }

  Future<void> _rejectResult() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recusar resultado'),
        content: const Text(
          'O placar voltará para pendente e qualquer participante poderá informar novamente.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Recusar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(challengesRepositoryProvider).rejectResult(widget.challengeId);
      bumpChallengesRefresh(ref);
      await _load();
      if (mounted) {
        showToast(context, 'Resultado recusado.');
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar desafio'),
        content: const Text('Tem certeza que deseja cancelar este desafio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancelar desafio')),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => ref.read(challengesRepositoryProvider).cancel(_challenge!.id));
      if (mounted) context.pop();
    }
  }

  bool get _showCandidates {
    final c = _challenge;
    if (c == null) return false;
    return c.role == 'created' &&
        c.type == ChallengeType.public &&
        (c.status == ChallengeStatus.pendingCandidates ||
            c.status == ChallengeStatus.candidatesAwaitingAccept);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (_loading) return const Scaffold(body: LoadingView());
    if (_error != null || _challenge == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Desafio'),
              Expanded(
                child: ErrorView(
                  message: _error ?? 'Desafio não encontrado',
                  onRetry: _load,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final c = _challenge!;
    final df = DateFormat('EEE, dd/MM/yyyy · HH:mm', 'pt_BR');
    final isCreator = c.role == 'created';
    final currentUserId = ref.watch(authStateProvider).value?.id ?? 0;
    final isPublic = c.type == ChallengeType.public;
    final showCreatorLink = c.creator.id != currentUserId;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Desafio',
              trailing: c.canEditAsCreator && isCreator
                  ? CircleIconButton(
                      icon: Symbols.edit_rounded,
                      onTap: () => context.push('/challenges/${c.id}/edit'),
                      tooltip: 'Editar',
                    )
                  : null,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    14, 4, 14, screenBottomInset(context) + 20),
                children: [
                  // Main card: creator, badges, score, message.
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: showCreatorLink
                              ? () => context.push('/players/${c.creator.id}')
                              : null,
                          child: Row(
                            children: [
                              UserAvatar(
                                name: c.creator.name,
                                avatarUrl: c.creator.avatarUrl,
                                hasCustomAvatar: c.creator.hasCustomAvatar,
                                userId: c.creator.id,
                                radius: 27,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.creator.id == currentUserId
                                          ? 'Seu desafio'
                                          : c.creator.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: t.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c.displayStatusLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12.5, color: t.muted),
                                    ),
                                  ],
                                ),
                              ),
                              if (showCreatorLink)
                                Icon(Symbols.chevron_right_rounded,
                                    size: 20, color: t.disabled),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
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
                        if ((c.result?.scoreLabel ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 9),
                            decoration: BoxDecoration(
                              color: t.surface2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              c.result!.scoreLabel!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: t.text,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ],
                        if ((c.message ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: t.accent, width: 2.5),
                              ),
                            ),
                            child: Text(
                              '“${c.message!}”',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: t.muted,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Info card: QUANDO / ONDE / FORMATO.
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: InfoRow.labeled(
                            icon: Symbols.schedule_rounded,
                            label: 'Quando',
                            value: df.format(c.scheduledStart),
                            meta: c.scheduledEnd != null
                                ? 'até ${formatDateTimePt(c.scheduledEnd!)}'
                                : null,
                          ),
                        ),
                        Divider(height: 1, color: t.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: c.place != null
                                ? () => context.push('/places/${c.place!.id}')
                                : null,
                            child: InfoRow.labeled(
                              icon: Symbols.location_on_rounded,
                              label: 'Onde',
                              value: c.place?.name ?? 'Local em aberto',
                              meta: c.place != null
                                  ? [
                                      c.place!.subtitle,
                                      if (c.distanceKm != null)
                                        'a ${c.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
                                    ].where((s) => s.isNotEmpty).join(' · ')
                                  : 'A combinar com o adversário',
                            ),
                          ),
                        ),
                        Divider(height: 1, color: t.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: InfoRow.labeled(
                            icon: Symbols.sports_tennis_rounded,
                            label: 'Formato',
                            value:
                                '${c.format.label} · ${c.minNtrp != null ? 'NTRP ${ntrpValueLabel(c.minNtrp!)} – ${c.maxNtrp != null ? ntrpValueLabel(c.maxNtrp!) : '—'}' : 'Nível equivalente'}',
                            meta: (c.professionPreference ?? '').isNotEmpty
                                ? 'Preferência: ${c.professionPreference}'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AndamentoCard(challenge: c),
                  if (c.hasProposedResult) ...[
                    const SizedBox(height: 12),
                    ChallengeResultSection(
                        challenge: c, currentUserId: currentUserId),
                  ],
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Participantes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ChallengeParticipantsVersus(challenge: c),
                      ],
                    ),
                  ),
                  if (c.place != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: StaticPlaceMap(
                        latitude: c.place!.latitude,
                        longitude: c.place!.longitude,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ..._actions(c, isCreator),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(Challenge c, bool isCreator) {
    final t = context.t;
    final repo = ref.read(challengesRepositoryProvider);
    final actions = <Widget>[];

    void add(Widget w) {
      if (actions.isNotEmpty) actions.add(const SizedBox(height: 8));
      actions.add(w);
    }

    if (c.status == ChallengeStatus.pendingAcceptance && c.role == 'received') {
      add(LimeButton(
        label: 'Aceitar',
        glow: true,
        onPressed: _busy ? null : () => _run(() => repo.accept(c.id)),
      ));
      add(LimeButton(
        label: 'Recusar',
        outlined: true,
        danger: true,
        onPressed: _busy ? null : () => _run(() => repo.decline(c.id)),
      ));
    }
    if (_showCandidates) {
      add(LimeButton(
        label: 'Ver candidatos (${c.candidatesCount})',
        outlined: true,
        onPressed: () => context
            .push('/challenges/${c.id}/candidates')
            .then((_) => _load()),
      ));
    }
    if (c.status == ChallengeStatus.pendingCandidates && c.role != 'created') {
      add(LimeButton(
        label: c.hasApplied ? 'Candidatura enviada' : 'Candidatar-se',
        glow: !c.hasApplied,
        onPressed: _busy || c.hasApplied
            ? null
            : () => _run(() => repo.apply(c.id)),
      ));
    }
    if (c.canSubmitResult) {
      add(LimeButton(
        label: 'Informar resultado',
        glow: true,
        onPressed:
            _busy ? null : () => context.push('/challenges/${c.id}/evaluation'),
      ));
    }
    if (c.canApproveResult) {
      add(LimeButton(
        label: 'Aprovar resultado',
        glow: true,
        loading: _busy,
        onPressed: _busy ? null : _approveResult,
      ));
    }
    if (c.canRejectResult) {
      add(LimeButton(
        label: 'Recusar resultado',
        outlined: true,
        danger: true,
        loading: _busy,
        onPressed: _busy ? null : _rejectResult,
      ));
    }
    if (isCreator &&
        c.status != ChallengeStatus.cancelled &&
        c.status != ChallengeStatus.completed &&
        c.status != ChallengeStatus.declined &&
        c.status != ChallengeStatus.expired &&
        c.status != ChallengeStatus.pendingResultApproval) {
      add(LimeButton(
        label: 'Cancelar desafio',
        outlined: true,
        danger: true,
        onPressed: _busy ? null : _confirmCancel,
      ));
    }
    if (c.status == ChallengeStatus.completed) {
      add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Resultado confirmado por todos. Não é possível alterar o placar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: t.muted),
        ),
      ));
    }
    return actions;
  }
}

/// Prototype "Andamento" vertical stepper.
class _AndamentoCard extends StatelessWidget {
  const _AndamentoCard({required this.challenge});

  final Challenge challenge;

  static const _steps = [
    'Desafio criado',
    'Aceito e agendado',
    'Partida disputada',
    'Resultado avaliado',
  ];

  int get _doneCount => switch (challenge.status) {
        ChallengeStatus.pendingAcceptance ||
        ChallengeStatus.pendingCandidates ||
        ChallengeStatus.candidatesAwaitingAccept =>
          1,
        ChallengeStatus.accepted => 2,
        ChallengeStatus.pendingScore ||
        ChallengeStatus.pendingResultApproval =>
          3,
        ChallengeStatus.completed => 4,
        _ => 1,
      };

  bool get _terminated =>
      challenge.status == ChallengeStatus.cancelled ||
      challenge.status == ChallengeStatus.declined ||
      challenge.status == ChallengeStatus.expired;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final done = _doneCount;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Andamento',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: t.text,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i < done ? t.accent : t.surface2,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          i < done
                              ? Symbols.check_rounded
                              : Symbols.schedule_rounded,
                          size: 15,
                          weight: 700,
                          color: i < done ? t.onAccent : t.disabled,
                        ),
                      ),
                      if (i < _steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            constraints: const BoxConstraints(minHeight: 14),
                            color: i < done - 1 ? t.accent : t.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: 4, bottom: i < _steps.length - 1 ? 16 : 4),
                      child: Text(
                        _steps[i],
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              i < done ? FontWeight.w700 : FontWeight.w500,
                          color: i < done ? t.text : t.disabled,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_terminated) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: t.tintErr,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Symbols.block_rounded, size: 16, color: t.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      challenge.displayStatusLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: t.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
