import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/challenge_status_chip.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:intl/intl.dart';

class ChallengesWallScreen extends ConsumerStatefulWidget {
  const ChallengesWallScreen({super.key});

  @override
  ConsumerState<ChallengesWallScreen> createState() => _ChallengesWallScreenState();
}

class _ChallengesWallScreenState extends ConsumerState<ChallengesWallScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  ChallengeListRole _role = ChallengeListRole.created;
  List<Challenge> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() {
          _role = _tabs.index == 0 ? ChallengeListRole.created : ChallengeListRole.received;
        });
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(challengesRepositoryProvider).list(_role);
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(challengesRefreshProvider, (previous, next) => _load());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural de Desafios'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'CRIADOS'),
            Tab(text: 'RECEBIDOS'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingView(message: 'Carregando desafios...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('Nenhum desafio nesta lista.')),
                          ],
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, screenBottomInset(context) + 16),
                          children: _items.map(_ChallengeCard.new).toList(),
                        ),
                ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard(this.challenge);

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd/MM, HH:mm', 'pt_BR');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      challenge.type == ChallengeType.public
                          ? '${challenge.format.label} ${challenge.minNtrp?.toStringAsFixed(1) ?? ''}'
                          : challenge.creator.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ChallengeStatusChip(status: challenge.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(df.format(challenge.scheduledStart)),
              if (challenge.place != null) Text('Local: ${challenge.place!.name}'),
              if (challenge.type == ChallengeType.public && challenge.candidatesCount > 0)
                Text('${challenge.candidatesCount} candidato(s)'),
            ],
          ),
        ),
      ),
    );
  }
}
