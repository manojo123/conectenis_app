import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/features/players/data/players_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/nearby_court.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/utils/challenge_ntrp_bounds.dart';
import 'package:conectenis_app/shared/utils/date_time_format.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/bottom_action_bar.dart';
import 'package:conectenis_app/shared/widgets/challenge_ntrp_range_picker.dart';
import 'package:conectenis_app/shared/widgets/gender_multi_selector.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/place_select_field.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/section_label.dart';
import 'package:conectenis_app/shared/widgets/segmented_tabs.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

/// Prototype "Novo desafio": one screen with a Direto/Público toggle that
/// swaps the opponent picker for the NTRP-range/preference section.
class NewChallengeScreen extends ConsumerStatefulWidget {
  const NewChallengeScreen({
    super.key,
    this.initialType = ChallengeType.direct,
    this.opponentId,
    this.initialCourt,
  });

  final ChallengeType initialType;
  final int? opponentId;

  /// Pre-fills "Local" — e.g. arriving from the map's CRIAR DESAFIO AQUI.
  final NearbyCourt? initialCourt;

  @override
  ConsumerState<NewChallengeScreen> createState() => _NewChallengeScreenState();
}

class _NewChallengeScreenState extends ConsumerState<NewChallengeScreen> {
  late ChallengeType _type = widget.initialType;

  // Direct state.
  ChallengeFormat _format = ChallengeFormat.singles;
  final Map<int, Player> _opponents = {};

  // Public state.
  final Set<ChallengeFormat> _publicFormats = {ChallengeFormat.singles};
  double _minNtrp = 3.0;
  double _maxNtrp = 3.0;
  bool _ntrpInitialized = false;
  Set<Gender> _genderPrefs = {};
  bool _openLocation = false;

  // Shared state.
  DateTime _start =
      roundToFiveMinutes(DateTime.now().add(const Duration(days: 1)));
  DateTime _end =
      roundToFiveMinutes(DateTime.now().add(const Duration(days: 1, hours: 2)));
  NearbyCourt? _court;
  final _messageController = TextEditingController();
  bool _submitting = false;

  int get _maxOpponents => _format.slotsTotal - 1;

  @override
  void initState() {
    super.initState();
    if (widget.opponentId != null) {
      _loadInitialOpponent(widget.opponentId!);
    }
    _court = widget.initialCourt;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialOpponent(int id) async {
    final player = await ref.read(playersRepositoryProvider).byId(id);
    if (player != null && mounted) {
      setState(() => _opponents[id] = player);
    }
  }

  void _ensureNtrpDefaults(double userNtrp) {
    if (_ntrpInitialized) return;
    _ntrpInitialized = true;
    final lo = ChallengeNtrpBounds.allowedMin(userNtrp);
    final hi = ChallengeNtrpBounds.allowedMax(userNtrp);
    final target = userNtrp.clamp(lo, hi);
    _minNtrp = target;
    _maxNtrp = target;
  }

  Future<void> _pickStart() async {
    final picked = await pickDateTimeWithFiveMinuteSteps(
      context,
      initial: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        if (!_end.isAfter(picked)) {
          _end = picked.add(const Duration(hours: 2));
        }
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await pickDateTimeWithFiveMinuteSteps(
      context,
      initial: _end,
      firstDate: _start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _end = picked);
  }

  Future<void> _pickOpponents() async {
    final selected = await context.push<Player>('/players-search?select=true');
    if (selected == null || !mounted) return;
    setState(() {
      if (_format == ChallengeFormat.singles) {
        _opponents
          ..clear()
          ..[selected.id] = selected;
      } else if (!_opponents.containsKey(selected.id) &&
          _opponents.length < _maxOpponents) {
        _opponents[selected.id] = selected;
      }
    });
  }

  bool get _isDirect => _type == ChallengeType.direct;

  String? get _validationHint {
    if (_isDirect) {
      if (_opponents.isEmpty) return 'Escolha o adversário para enviar';
      if (_opponents.length < _maxOpponents) {
        return 'Duplas: escolha ${_maxOpponents - _opponents.length} adversário(s) a mais';
      }
      if (_court == null) return 'Escolha o local da partida';
    } else {
      if (_publicFormats.isEmpty) return 'Selecione simples e/ou duplas';
      if (!_openLocation && _court == null) {
        return 'Escolha um local ou deixe em aberto';
      }
    }
    if (!_end.isAfter(_start)) return 'O término deve ser após o início';
    return null;
  }

  Future<void> _submit(double userNtrp) async {
    final hint = _validationHint;
    if (hint != null) {
      showToast(context, hint);
      return;
    }
    if (!_isDirect &&
        !ChallengeNtrpBounds.isValidRange(
          userNtrp: userNtrp,
          minNtrp: _minNtrp,
          maxNtrp: _maxNtrp,
        )) {
      final lo = ChallengeNtrpBounds.allowedMin(userNtrp);
      final hi = ChallengeNtrpBounds.allowedMax(userNtrp);
      showToast(
        context,
        'O nível do desafio deve ficar entre ${ntrpValueLabel(lo)} e ${ntrpValueLabel(hi)}.',
      );
      return;
    }

    final message = _messageController.text.trim();
    setState(() => _submitting = true);
    try {
      final repo = ref.read(challengesRepositoryProvider);
      if (_isDirect) {
        await repo.createDirect(
          format: _format,
          participantIds: _opponents.keys.toList(),
          placeId: _court!.placeId,
          googlePlaceId: _court!.googlePlaceId,
          scheduledStart: _start,
          scheduledEnd: _end,
          message: message.isEmpty ? null : message,
        );
      } else {
        for (final format in _publicFormats) {
          await repo.createPublic(
            format: format,
            scheduledStart: _start,
            scheduledEnd: _end,
            openLocation: _openLocation,
            placeId: _openLocation ? null : _court?.placeId,
            googlePlaceId: _openLocation ? null : _court?.googlePlaceId,
            minNtrp: _minNtrp,
            maxNtrp: _maxNtrp,
            genderPreference: genderPreferenceFromSet(_genderPrefs),
            message: message.isEmpty ? null : message,
          );
        }
      }
      bumpChallengesRefresh(ref);
      if (!mounted) return;
      showToast(
        context,
        _isDirect
            ? 'Desafio enviado a ${_opponents.values.first.name.split(' ').first}!'
            : 'Desafio publicado no mural!',
      );
      context.go('/challenges');
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final userNtrp = ref.watch(authStateProvider).value?.ntrpRating ?? 3.0;
    _ensureNtrpDefaults(userNtrp);
    final hint = _validationHint;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Novo desafio', close: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  const SectionLabel('Tipo de desafio'),
                  const SizedBox(height: 9),
                  SegmentedTabs(
                    labels: const ['Direto', 'Público'],
                    index: _isDirect ? 0 : 1,
                    onChanged: (i) => setState(() =>
                        _type = i == 0 ? ChallengeType.direct : ChallengeType.public),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isDirect
                        ? 'Convide um jogador específico. Só ele verá o desafio.'
                        : 'Publicado no mural para jogadores do nível escolhido se candidatarem.',
                    style: TextStyle(fontSize: 12, color: t.muted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  if (_isDirect) ..._directSection(t) else ..._publicSection(t, userNtrp),
                  const SizedBox(height: 20),
                  const SectionLabel('Data e horário'),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: _dateTile(
                            t, 'INÍCIO', formatDateTimePt(_start), _pickStart),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _dateTile(
                            t, 'TÉRMINO', formatDateTimePt(_end), _pickEnd),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionLabel('Local'),
                  const SizedBox(height: 9),
                  if (!_isDirect) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() {
                        _openLocation = !_openLocation;
                        if (_openLocation) _court = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: t.surface,
                          border: Border.all(
                            color: _openLocation ? t.accent : t.border,
                            width: _openLocation ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _openLocation
                                    ? t.accent
                                    : Colors.transparent,
                                border: Border.all(
                                  color:
                                      _openLocation ? t.accent : t.disabled,
                                  width: 2,
                                ),
                              ),
                              child: _openLocation
                                  ? Icon(Symbols.check_rounded,
                                      size: 13, weight: 700, color: t.onAccent)
                                  : null,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Local em aberto',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: t.text,
                                    ),
                                  ),
                                  Text(
                                    'A combinar com quem se candidatar',
                                    style: TextStyle(
                                        fontSize: 11.5, color: t.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_isDirect || !_openLocation)
                    PlaceSelectField(
                      selectedCourt: _court,
                      onChanged: (court) => setState(() => _court = court),
                    ),
                  const SizedBox(height: 20),
                  SectionLabel(
                    'Mensagem',
                    trailing: Text(
                      '(opcional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.disabled,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ex.: Jogo tranquilo, foco em treinar backhand…',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        hint: hint,
        child: LimeButton(
          label: _isDirect ? 'Enviar desafio' : 'Publicar no mural',
          glow: hint == null,
          loading: _submitting,
          onPressed:
              _submitting || hint != null ? null : () => _submit(userNtrp),
        ),
      ),
    );
  }

  List<Widget> _directSection(AppTokens t) {
    return [
      const SectionLabel('Formato'),
      const SizedBox(height: 9),
      SegmentedTabs(
        labels: ChallengeFormat.values.map((f) => f.label).toList(),
        index: ChallengeFormat.values.indexOf(_format),
        onChanged: (i) => setState(() {
          _format = ChallengeFormat.values[i];
          if (_format == ChallengeFormat.singles && _opponents.length > 1) {
            final first = _opponents.values.first;
            _opponents
              ..clear()
              ..[first.id] = first;
          }
        }),
      ),
      const SizedBox(height: 20),
      SectionLabel(
        _format == ChallengeFormat.singles ? 'Adversário' : 'Adversários',
        trailing: Text(
          '${_opponents.length}/$_maxOpponents',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: t.muted,
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 110,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final player in _opponents.values)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => setState(() => _opponents.remove(player.id)),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: t.accent, width: 3),
                            ),
                            child: UserAvatar(
                              name: player.name,
                              avatarUrl: player.avatarUrl,
                              hasCustomAvatar: player.hasCustomAvatar,
                              userId: player.id,
                              radius: 26,
                            ),
                          ),
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: t.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: t.bg, width: 2),
                              ),
                              child: const Icon(Symbols.close_rounded,
                                  size: 12, weight: 700, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        player.name.split(' ').first,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                      Text(
                        ntrpValueLabel(player.ntrpRating),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: t.accentText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_opponents.length < _maxOpponents)
              PressableScale(
                onTap: _pickOpponents,
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.surface,
                        border: Border.all(color: t.border, width: 1.5),
                      ),
                      child:
                          Icon(Symbols.person_search_rounded, size: 24, color: t.muted),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Buscar',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: t.muted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _publicSection(AppTokens t, double userNtrp) {
    return [
      const SectionLabel('Faixa de nível (NTRP)'),
      const SizedBox(height: 9),
      ChallengeNtrpRangePicker(
        userNtrp: userNtrp,
        minNtrp: _minNtrp,
        maxNtrp: _maxNtrp,
        onChanged: (values) => setState(() {
          _minNtrp = values.start;
          _maxNtrp = values.end;
        }),
      ),
      const SizedBox(height: 18),
      const SectionLabel('Modalidade'),
      const SizedBox(height: 9),
      Row(
        children: [
          for (final format in ChallengeFormat.values) ...[
            if (format != ChallengeFormat.values.first) const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  if (_publicFormats.contains(format)) {
                    if (_publicFormats.length > 1) {
                      _publicFormats.remove(format);
                    }
                  } else {
                    _publicFormats.add(format);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _publicFormats.contains(format)
                        ? t.accent
                        : t.surface,
                    border: Border.all(
                      color: _publicFormats.contains(format)
                          ? Colors.transparent
                          : t.border,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    format.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _publicFormats.contains(format)
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: _publicFormats.contains(format)
                          ? t.onAccent
                          : t.muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 18),
      const SectionLabel('Preferência de gênero'),
      const SizedBox(height: 9),
      GenderMultiSelector(
        selected: _genderPrefs,
        onChanged: (g) => setState(() => _genderPrefs = g),
      ),
    ];
  }

  Widget _dateTile(AppTokens t, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: t.inputBg,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.calendar_month_rounded, size: 15, color: t.muted),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: t.disabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
