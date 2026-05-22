import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/features/play_invitations/data/play_invitations_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/play_invitation.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/report_reason_sheet.dart';
import 'package:conectenis_app/shared/widgets/star_rating_input.dart';

class InvitationDetailScreen extends ConsumerStatefulWidget {
  const InvitationDetailScreen({super.key, required this.invitationId});

  final int invitationId;

  @override
  ConsumerState<InvitationDetailScreen> createState() => _InvitationDetailScreenState();
}

class _InvitationDetailScreenState extends ConsumerState<InvitationDetailScreen> {
  PlayInvitation? _invitation;
  bool _loading = true;
  String? _error;
  bool _busy = false;
  int _playerStars = 0;
  int _placeStars = 0;
  final _playerCommentController = TextEditingController();

  @override
  void dispose() {
    _playerCommentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  int? get _userId => ref.read(authStateProvider).valueOrNull?.id;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inv = await ref.read(playInvitationsRepositoryProvider).byId(widget.invitationId);
      setState(() {
        _invitation = inv;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = authErrorMessage(e);
      });
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView(message: 'Carregando convite...'));
    }
    if (_error != null || _invitation == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: _error ?? 'Convite não encontrado', onRetry: _load),
      );
    }

    final inv = _invitation!;
    final userId = _userId ?? 0;
    final isInviter = inv.isInviter(userId);
    final opponent = inv.opponentFor(userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Convite')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _StatusChip(status: inv.status),
          const SizedBox(height: 16),
          Text(opponent.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place),
            title: Text(inv.place.name),
            subtitle: Text(inv.place.subtitle),
            onTap: () => context.push('/places/${inv.place.id}'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(_formatDateTime(inv.scheduledAt)),
          ),
          if (inv.message != null && inv.message!.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.message_outlined),
              title: Text(inv.message!),
            ),
          const Divider(height: 32),
          ..._buildActions(inv, userId, isInviter),
          if (inv.status == PlayInvitationStatus.completed) ...[
            const Divider(height: 32),
            Text('Após o jogo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (!inv.hasRatedOpponent) ...[
              const Text('Avaliar jogador'),
              StarRatingInput(
                value: _playerStars,
                onChanged: (v) => setState(() => _playerStars = v),
              ),
              TextField(
                controller: _playerCommentController,
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy || _playerStars < 1
                    ? null
                    : () => _runAction(() async {
                          await ref.read(playInvitationsRepositoryProvider).ratePlayer(
                                id: inv.id,
                                stars: _playerStars,
                                comment: _playerCommentController.text.trim(),
                              );
                        }),
                child: const Text('Salvar avaliação do jogador'),
              ),
            ] else
              const Text('Você já avaliou este jogador.'),
            const SizedBox(height: 16),
            const Text('Avaliar local'),
            StarRatingInput(
              value: _placeStars,
              onChanged: (v) => setState(() => _placeStars = v),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _busy || _placeStars < 1
                  ? null
                  : () => _runAction(() async {
                        await ref.read(placesRepositoryProvider).rate(
                              id: inv.place.id,
                              stars: _placeStars,
                            );
                      }),
              child: const Text('Avaliar local'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _reportPlayer(inv),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Denunciar jogador'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _reportPlace(inv),
              icon: const Icon(Icons.report_outlined),
              label: const Text('Reportar local'),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions(PlayInvitation inv, int userId, bool isInviter) {
    if (_busy) {
      return [const Center(child: CircularProgressIndicator())];
    }
    switch (inv.status) {
      case PlayInvitationStatus.pending:
        if (isInviter) {
          return [
            FilledButton(
              onPressed: () => _runAction(() => ref.read(playInvitationsRepositoryProvider).cancel(inv.id)),
              child: const Text('Cancelar convite'),
            ),
          ];
        }
        return [
          FilledButton(
            onPressed: () => _runAction(() => ref.read(playInvitationsRepositoryProvider).accept(inv.id)),
            child: const Text('Aceitar'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _runAction(() => ref.read(playInvitationsRepositoryProvider).decline(inv.id)),
            child: const Text('Recusar'),
          ),
        ];
      case PlayInvitationStatus.accepted:
        return [
          FilledButton(
            onPressed: () => _runAction(() => ref.read(playInvitationsRepositoryProvider).complete(inv.id)),
            child: const Text('Marcar como realizada'),
          ),
        ];
      default:
        return [];
    }
  }

  Future<void> _reportPlayer(PlayInvitation inv) async {
    final result = await showReportReasonSheet(
      context: context,
      title: 'Denunciar jogador',
      reasons: UserReportReason.values
          .map((r) => (value: r.value, label: r.label))
          .toList(),
    );
    if (result == null) return;
    await _runAction(() async {
      await ref.read(playInvitationsRepositoryProvider).reportPlayer(
            id: inv.id,
            reason: UserReportReason.fromValue(result.reason),
            details: result.details,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Denúncia enviada.')),
        );
      }
    });
  }

  Future<void> _reportPlace(PlayInvitation inv) async {
    final result = await showReportReasonSheet(
      context: context,
      title: 'Reportar local',
      reasons: PlaceReportReason.values
          .map((r) => (value: r.value, label: r.label))
          .toList(),
    );
    if (result == null) return;
    await _runAction(() async {
      await ref.read(placesRepositoryProvider).report(
            id: inv.place.id,
            reason: PlaceReportReason.fromValue(result.reason),
            details: result.details,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Denúncia enviada.')),
        );
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PlayInvitationStatus status;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(label: Text(status.label)),
    );
  }
}
