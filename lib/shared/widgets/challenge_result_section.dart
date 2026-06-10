import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/challenge_result.dart';
import 'package:conectenis_app/shared/models/enums.dart';

class ChallengeResultSection extends StatelessWidget {
  const ChallengeResultSection({
    super.key,
    required this.challenge,
    required this.currentUserId,
  });

  final Challenge challenge;
  final int currentUserId;

  @override
  Widget build(BuildContext context) {
    final result = challenge.result;
    if (result == null) return const SizedBox.shrink();

    final approved = result.approvalCount(challenge.requiredApprovalCount);
    final total = challenge.requiredApprovalCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultado proposto', style: Theme.of(context).textTheme.titleSmall),
            if (result.submittedByName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Informado por ${result.submittedByName}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            if (result.skipScore)
              const Text('Placar não informado')
            else if (result.scoreLabel != null && result.scoreLabel!.isNotEmpty)
              Text(result.scoreLabel!, style: Theme.of(context).textTheme.titleMedium)
            else if (result.myGamesWon != null && result.opponentGamesWon != null)
              Text(
                'Placar: ${result.myGamesWon} × ${result.opponentGamesWon}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            if (result.winnerName != null) ...[
              const SizedBox(height: 4),
              Text('Vencedor: ${result.winnerName}'),
            ] else if (result.winnerTeamLabel != null) ...[
              const SizedBox(height: 4),
              Text('Dupla vencedora: ${result.winnerTeamLabel}'),
            ] else if (result.winnerTeamIds.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Dupla vencedora: ${result.winnerTeamIds.map((id) => challenge.participantName(id)).whereType<String>().join(' / ')}',
              ),
            ],
            if (result.opponentRatings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Avaliações dos adversários', style: Theme.of(context).textTheme.titleSmall),
              ...result.opponentRatings.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.userName}: ${'★' * r.punctualityStars}'),
                      if (r.comment != null && r.comment!.isNotEmpty) Text(r.comment!),
                    ],
                  ),
                ),
              ),
            ] else if (result.opponentPunctualityStars != null) ...[
              const SizedBox(height: 8),
              Text('Avaliação do adversário: ${'★' * result.opponentPunctualityStars!}'),
              if (result.opponentComment != null && result.opponentComment!.isNotEmpty)
                Text(result.opponentComment!),
            ],
            if (result.placeQualityStars != null) ...[
              const SizedBox(height: 8),
              Text('Avaliação do local: ${'★' * result.placeQualityStars!}'),
              if (result.placeComment != null && result.placeComment!.isNotEmpty)
                Text(result.placeComment!),
            ],
            const Divider(height: 24),
            Text(
              'Aprovações ($approved/$total)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...challenge.participantUserIds.map((userId) {
              final name = challenge.participantName(userId) ?? 'Jogador';
              ChallengeResultApproval? approval;
              for (final a in result.approvals) {
                if (a.userId == userId) {
                  approval = a;
                  break;
                }
              }
              final ok = approval?.approved == true;
              final isMe = userId == currentUserId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  ok ? Icons.check_circle : Icons.hourglass_empty,
                  color: ok ? AppColors.success : AppColors.warning,
                  size: 20,
                ),
                title: Text(isMe ? '$name (você)' : name),
                subtitle: Text(ok ? 'Aprovou' : 'Pendente'),
              );
            }),
            if (challenge.status == ChallengeStatus.pendingResultApproval) ...[
              const SizedBox(height: 8),
              const Text(
                'Todos os participantes precisam aprovar antes do desafio ser marcado como Realizado.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
