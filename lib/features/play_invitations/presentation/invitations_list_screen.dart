import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/play_invitations/data/play_invitations_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/play_invitation.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class InvitationsListScreen extends ConsumerStatefulWidget {
  const InvitationsListScreen({super.key});

  @override
  ConsumerState<InvitationsListScreen> createState() => _InvitationsListScreenState();
}

class _InvitationsListScreenState extends ConsumerState<InvitationsListScreen> {
  InvitationListRole _role = InvitationListRole.all;
  AsyncValue<List<PlayInvitation>> _invitations = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _invitations = const AsyncLoading());
    try {
      final list = await ref.read(playInvitationsRepositoryProvider).list(role: _role);
      setState(() => _invitations = AsyncData(list));
    } catch (e, st) {
      setState(() => _invitations = AsyncError(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convites'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<InvitationListRole>(
              segments: InvitationListRole.values
                  .map(
                    (r) => ButtonSegment(
                      value: r,
                      label: Text(r.label, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              selected: {_role},
              onSelectionChanged: (s) {
                setState(() => _role = s.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _invitations.when(
              loading: () => const LoadingView(message: 'Carregando convites...'),
              error: (e, _) => ErrorView(
                message: authErrorMessage(e),
                onRetry: _load,
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.mail_outline,
                    title: 'Nenhum convite',
                    subtitle:
                        'Convide jogadores pelo perfil deles. Convites recebidos aparecem aqui.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final inv = list[i];
                      final opponent = inv.role == 'sent' ? inv.invitee : inv.inviter;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.lime.withValues(alpha: 0.3),
                          child: Text(opponent.name[0]),
                        ),
                        title: Text(opponent.name),
                        subtitle: Text(
                          '${inv.place.name}\n${_formatDateTime(inv.scheduledAt)}',
                        ),
                        isThreeLine: true,
                        trailing: _StatusChip(status: inv.status),
                        onTap: () async {
                          await context.push('/invitations/${inv.id}');
                          if (mounted) _load();
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PlayInvitationStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }
}
