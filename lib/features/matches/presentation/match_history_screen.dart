import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:conectenis_app/features/matches/data/matches_repository.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class MatchHistoryScreen extends ConsumerStatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  ConsumerState<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends ConsumerState<MatchHistoryScreen> {
  bool _rivals = true;
  AsyncValue<dynamic> _data = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _data = const AsyncLoading());
    try {
      if (_rivals) {
        final list = await ref.read(matchesRepositoryProvider).rivals();
        setState(() => _data = AsyncData(list));
      } else {
        final list = await ref.read(matchesRepositoryProvider).list();
        setState(() => _data = AsyncData(list));
      }
    } catch (e, st) {
      setState(() => _data = AsyncError(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Rivais')),
                ButtonSegment(value: false, label: Text('Partidas')),
              ],
              selected: {_rivals},
              onSelectionChanged: (s) {
                setState(() => _rivals = s.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _data.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(message: e.toString(), onRetry: _load),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: _rivals ? 'Nenhum rival ainda' : 'Nenhuma partida',
                      subtitle: 'Registre sua primeira partida no perfil.',
                    );
                  }
                  if (_rivals) {
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final r = list[i];
                        return ListTile(
                          title: Text(r.opponentName),
                          subtitle: Text('${r.wins} vitórias · ${r.losses} derrotas'),
                          trailing: Text(
                            '${r.wins + r.losses} jogos',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final m = list[i];
                      return ListTile(
                        title: Text('vs ${m.opponentName}'),
                        subtitle: Text(DateFormat.yMMMd('pt_BR').format(m.playedAt)),
                        trailing: Text(
                          '${m.playerScore} - ${m.opponentScore}',
                          style: TextStyle(
                            color: m.won ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
