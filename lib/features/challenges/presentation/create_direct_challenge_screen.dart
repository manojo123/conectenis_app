import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/utils/date_time_format.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/place_selector_field.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class CreateDirectChallengeScreen extends ConsumerStatefulWidget {
  const CreateDirectChallengeScreen({super.key, this.opponentId});

  final int? opponentId;

  @override
  ConsumerState<CreateDirectChallengeScreen> createState() => _CreateDirectChallengeScreenState();
}

class _CreateDirectChallengeScreenState extends ConsumerState<CreateDirectChallengeScreen> {
  ChallengeFormat _format = ChallengeFormat.singles;
  final Map<int, Player> _opponents = {};
  Place? _place;
  DateTime _start = roundToFiveMinutes(DateTime.now().add(const Duration(days: 1)));
  bool _submitting = false;

  int get _maxOpponents => _format.slotsTotal - 1;

  @override
  void initState() {
    super.initState();
    if (widget.opponentId != null) {
      _loadInitialOpponent(widget.opponentId!);
    }
  }

  Future<void> _loadInitialOpponent(int id) async {
    final player = await ref.read(playersRepositoryProvider).byId(id);
    if (player != null && mounted) {
      setState(() => _opponents[id] = player);
    }
  }

  Future<void> _pickDateTime() async {
    final picked = await pickDateTimeWithFiveMinuteSteps(
      context,
      initial: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickOpponents() async {
    final selected = await context.push<Player>('/players-search?select=true');
    if (selected == null || !mounted) return;
    setState(() {
      if (_format == ChallengeFormat.singles) {
        _opponents
          ..clear()
          ..[selected.id] = selected;
      } else if (!_opponents.containsKey(selected.id) && _opponents.length < _maxOpponents) {
        _opponents[selected.id] = selected;
      }
    });
  }

  void _removeOpponent(int id) {
    setState(() => _opponents.remove(id));
  }

  Future<void> _submit() async {
    if (_opponents.isEmpty || _place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione adversário(s) e local')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(challengesRepositoryProvider).createDirect(
            format: _format,
            participantIds: _opponents.keys.toList(),
            placeId: _place!.id,
            scheduledStart: _start,
          );
      if (!mounted) return;
      context.go('/challenges');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDateTime(DateTime dt) => formatDateTimePt(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Desafio Direto')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          SegmentedButton<ChallengeFormat>(
            segments: ChallengeFormat.values
                .map((f) => ButtonSegment(value: f, label: Text(f.label)))
                .toList(),
            selected: {_format},
            onSelectionChanged: (s) => setState(() {
              _format = s.first;
              if (_format == ChallengeFormat.singles && _opponents.length > 1) {
                final first = _opponents.values.first;
                _opponents
                  ..clear()
                  ..[first.id] = first;
              }
            }),
          ),
          const SizedBox(height: 16),
          Text('Adversário(s)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_opponents.isEmpty)
            Text(
              'Nenhum adversário selecionado. Busque jogadores perto de você.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ..._opponents.values.map(
              (player) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: UserAvatar(name: player.name, avatarUrl: player.avatarUrl),
                  title: Text(player.name),
                  subtitle: Text('NTRP ${player.ntrpRating.toStringAsFixed(1)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeOpponent(player.id),
                  ),
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _opponents.length >= _maxOpponents ? null : _pickOpponents,
            icon: const Icon(Icons.person_search),
            label: Text(
              _opponents.isEmpty
                  ? 'Buscar jogador'
                  : 'Adicionar adversário (${_opponents.length}/$_maxOpponents)',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data e hora'),
            subtitle: Text(_formatDateTime(_start)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDateTime,
          ),
          const Divider(),
          const Text('Local'),
          const SizedBox(height: 8),
          PlaceSelectorField(
            selectedPlace: _place,
            onChanged: (place) => setState(() => _place = place),
          ),
          const SizedBox(height: 24),
          LimeButton(label: 'Confirmar envio', loading: _submitting, onPressed: _submit),
        ],
      ),
    );
  }
}
