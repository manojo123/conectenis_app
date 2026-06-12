import 'package:flutter/material.dart';
import 'package:conectenis_app/shared/models/challenge.dart';

class ChallengeHistorySection extends StatefulWidget {
  const ChallengeHistorySection({
    super.key,
    required this.items,
    required this.cardBuilder,
  });

  final List<Challenge> items;
  final Widget Function(Challenge challenge) cardBuilder;

  @override
  State<ChallengeHistorySection> createState() => _ChallengeHistorySectionState();
}

class _ChallengeHistorySectionState extends State<ChallengeHistorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(
            _expanded
                ? 'Ocultar histórico (${widget.items.length})'
                : 'Ver Histórico (${widget.items.length})',
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          ...widget.items.map(widget.cardBuilder),
        ],
      ],
    );
  }
}
