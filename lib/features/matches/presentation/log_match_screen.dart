import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/features/matches/data/matches_repository.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/player.dart';

class LogMatchScreen extends ConsumerStatefulWidget {
  const LogMatchScreen({super.key});

  @override
  ConsumerState<LogMatchScreen> createState() => _LogMatchScreenState();
}

class _LogMatchScreenState extends ConsumerState<LogMatchScreen> {
  Player? _opponent;
  final _myScore = TextEditingController(text: '6');
  final _theirScore = TextEditingController(text: '4');
  List<Player> _players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final list = await ref.read(playersRepositoryProvider).nearby(
          lat: MockData.centerLat,
          lng: MockData.centerLng,
        );
    setState(() {
      _players = list;
      _opponent = list.isNotEmpty ? list.first : null;
    });
  }

  @override
  void dispose() {
    _myScore.dispose();
    _theirScore.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_opponent == null) return;
    final my = int.tryParse(_myScore.text) ?? 0;
    final their = int.tryParse(_theirScore.text) ?? 0;
    await ref.read(matchesRepositoryProvider).log(
          opponentId: _opponent!.id,
          opponentName: _opponent!.name,
          playerScore: my,
          opponentScore: their,
          won: my > their,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partida registrada!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar partida')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DropdownButtonFormField<Player>(
            initialValue: _opponent,
            decoration: const InputDecoration(labelText: 'Adversário'),
            items: _players
                .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                .toList(),
            onChanged: (v) => setState(() => _opponent = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _myScore,
                  decoration: const InputDecoration(labelText: 'Seus games'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('x'),
              ),
              Expanded(
                child: TextField(
                  controller: _theirScore,
                  decoration: const InputDecoration(labelText: 'Games dele'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _submit, child: const Text('Salvar')),
        ],
      ),
    );
  }
}
