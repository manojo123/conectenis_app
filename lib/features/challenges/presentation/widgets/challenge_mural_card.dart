import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/challenge_status_chip.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';

class ChallengeMuralCard extends StatelessWidget {
  const ChallengeMuralCard({
    super.key,
    required this.challenge,
    this.highlightDirect = false,
    this.showApplyButton = false,
    this.onApply,
    this.applying = false,
  });

  final Challenge challenge;
  final bool highlightDirect;
  final bool showApplyButton;
  final VoidCallback? onApply;
  final bool applying;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd/MM, HH:mm', 'pt_BR');
    final distance = challenge.distanceKm;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: highlightDirect
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primary, width: 2),
            )
          : null,
      color: highlightDirect ? AppColors.primary.withValues(alpha: 0.06) : null,
      child: InkWell(
        onTap: () => context.push('/challenges/${challenge.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.creator.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ChallengeStatusChip(status: challenge.status),
                ],
              ),
              if (challenge.type == ChallengeType.public) ...[
                const SizedBox(height: 4),
                Text(
                  '${challenge.format.label} · NTRP '
                  '${challenge.minNtrp?.toStringAsFixed(1) ?? '—'}–'
                  '${challenge.maxNtrp?.toStringAsFixed(1) ?? '—'}'
                  '${distance != null ? ' · ${distance.toStringAsFixed(1)} km' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (highlightDirect) ...[
                const SizedBox(height: 4),
                Text(
                  'Desafio direto',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Text(df.format(challenge.scheduledStart)),
              if (challenge.place != null) Text('Local: ${challenge.place!.name}'),
              if (challenge.message != null && challenge.message!.isNotEmpty)
                Text(
                  challenge.message!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (showApplyButton) ...[
                const SizedBox(height: 12),
                LimeButton(
                  label: challenge.hasApplied ? 'Candidatura enviada' : 'Candidatar-se',
                  onPressed: challenge.hasApplied || applying ? null : onApply,
                  loading: applying,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
