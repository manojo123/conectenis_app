import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/star_rating_input.dart';

class ChallengeEvaluationScreen extends ConsumerStatefulWidget {
  const ChallengeEvaluationScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  ConsumerState<ChallengeEvaluationScreen> createState() => _ChallengeEvaluationScreenState();
}

class _ChallengeEvaluationScreenState extends ConsumerState<ChallengeEvaluationScreen> {
  bool _skipScore = false;
  final _myGames = TextEditingController();
  final _opponentGames = TextEditingController();
  int _punctuality = 0;
  int _placeQuality = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _myGames.dispose();
    _opponentGames.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_punctuality < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avalie a pontualidade do adversário')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(challengesRepositoryProvider).submitEvaluation(
            widget.challengeId,
            skipScore: _skipScore,
            myGamesWon: int.tryParse(_myGames.text),
            opponentGamesWon: int.tryParse(_opponentGames.text),
            opponentPunctualityStars: _punctuality,
            placeQualityStars: _placeQuality > 0 ? _placeQuality : null,
          );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliação do Desafio')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('INFORMAR PLACAR', style: Theme.of(context).textTheme.titleSmall),
          CheckboxListTile(
            value: _skipScore,
            onChanged: (v) => setState(() => _skipScore = v ?? false),
            title: const Text('Não quero informar o placar'),
          ),
          if (!_skipScore) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _myGames,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Games Vencidos'),
                  ),
                ),
                const Padding(padding: EdgeInsets.all(8), child: Text(':')),
                Expanded(
                  child: TextField(
                    controller: _opponentGames,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Games Adversário'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text('AVALIAR ADVERSÁRIO', style: Theme.of(context).textTheme.titleSmall),
          const Text('Pontualidade'),
          StarRatingInput(value: _punctuality, onChanged: (v) => setState(() => _punctuality = v)),
          const SizedBox(height: 24),
          Text('AVALIAR LOCAL', style: Theme.of(context).textTheme.titleSmall),
          const Text('Qualidade da quadra'),
          StarRatingInput(value: _placeQuality, onChanged: (v) => setState(() => _placeQuality = v)),
          const SizedBox(height: 32),
          LimeButton(label: 'Submeter avaliação', loading: _submitting, onPressed: _submit),
        ],
      ),
    );
  }
}
