import 'package:flutter/material.dart';
import 'package:conectenis_app/shared/widgets/star_rating_input.dart';

class PlaceRatingInput {
  int courtQualityStars = 0;
  int infrastructureStars = 0;
  final TextEditingController commentController = TextEditingController();

  bool get isComplete => courtQualityStars > 0 && infrastructureStars > 0;

  void dispose() => commentController.dispose();
}

class PlaceRatingForm extends StatelessWidget {
  const PlaceRatingForm({
    super.key,
    required this.placeName,
    required this.rating,
    required this.onChanged,
  });

  final String placeName;
  final PlaceRatingInput rating;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AVALIAR LOCAL', style: Theme.of(context).textTheme.titleSmall),
        Text(placeName),
        const SizedBox(height: 8),
        const Text('Qualidade da Quadra'),
        StarRatingInput(
          value: rating.courtQualityStars,
          onChanged: (v) {
            rating.courtQualityStars = v;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        const Text('Infraestrutura Geral'),
        StarRatingInput(
          value: rating.infrastructureStars,
          onChanged: (v) {
            rating.infrastructureStars = v;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: rating.commentController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Comentário sobre o local (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
