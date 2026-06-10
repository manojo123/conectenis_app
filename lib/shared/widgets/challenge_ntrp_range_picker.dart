import 'package:flutter/material.dart';
import 'package:conectenis_app/shared/utils/challenge_ntrp_bounds.dart';

class ChallengeNtrpRangePicker extends StatelessWidget {
  const ChallengeNtrpRangePicker({
    super.key,
    required this.userNtrp,
    required this.minNtrp,
    required this.maxNtrp,
    required this.onChanged,
  });

  final double userNtrp;
  final double minNtrp;
  final double maxNtrp;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final allowedMin = ChallengeNtrpBounds.allowedMin(userNtrp);
    final allowedMax = ChallengeNtrpBounds.allowedMax(userNtrp);
    final divisions = ChallengeNtrpBounds.sliderDivisions(allowedMin, allowedMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Seu nível: ${userNtrp.toStringAsFixed(1)} · faixa permitida: '
          '${allowedMin.toStringAsFixed(1)} – ${allowedMax.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Nível procurado: ${minNtrp.toStringAsFixed(1)} – ${maxNtrp.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        RangeSlider(
          min: allowedMin,
          max: allowedMax,
          divisions: divisions > 0 ? divisions : null,
          values: RangeValues(minNtrp, maxNtrp),
          labels: RangeLabels(
            minNtrp.toStringAsFixed(1),
            maxNtrp.toStringAsFixed(1),
          ),
          onChanged: onChanged,
        ),
        const Row(
          children: [
            Expanded(child: Text('Iniciante', overflow: TextOverflow.ellipsis)),
            Expanded(
              child: Text('Avançado', textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ],
    );
  }
}
