import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/nearby_court.dart';
import 'package:conectenis_app/shared/utils/challenge_ntrp_bounds.dart';
import 'package:conectenis_app/shared/utils/date_time_format.dart';
import 'package:conectenis_app/shared/widgets/challenge_ntrp_range_picker.dart';
import 'package:conectenis_app/shared/widgets/gender_multi_selector.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/place_select_field.dart';

class EditPublicChallengeScreen extends ConsumerStatefulWidget {
  const EditPublicChallengeScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  ConsumerState<EditPublicChallengeScreen> createState() => _EditPublicChallengeScreenState();
}

class _EditPublicChallengeScreenState extends ConsumerState<EditPublicChallengeScreen> {
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  final _messageController = TextEditingController();
  final _professionController = TextEditingController();
  double _minNtrp = 3.0;
  double _maxNtrp = 3.0;
  Set<Gender> _genderPrefs = {};
  DateTime? _start;
  DateTime? _end;
  bool _openLocation = false;
  NearbyCourt? _selectedCourt;

  @override
  void dispose() {
    _messageController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await ref.read(challengesRepositoryProvider).byId(widget.challengeId);
      if (!mounted) return;
      if (!c.canEditAsCreator) {
        setState(() {
          _loading = false;
          _error = 'Este desafio não pode mais ser editado.';
        });
        return;
      }
      _messageController.text = c.message ?? '';
      _professionController.text = c.professionPreference ?? '';
      _minNtrp = c.minNtrp ?? 3.0;
      _maxNtrp = c.maxNtrp ?? 3.0;
      if (c.genderPreference != null) {
        try {
          _genderPrefs = {Gender.values.firstWhere((g) => g.value == c.genderPreference)};
        } catch (_) {}
      }
      _start = c.scheduledStart;
      _end = c.scheduledEnd ?? c.scheduledStart.add(const Duration(hours: 2));
      _openLocation = c.openLocation;
      if (c.place != null) {
        _selectedCourt = NearbyCourt(
          placeId: c.place!.id,
          name: c.place!.name,
          latitude: c.place!.latitude,
          longitude: c.place!.longitude,
        );
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _pickStart() async {
    if (_start == null) return;
    final picked = await pickDateTimeWithFiveMinuteSteps(
      context,
      initial: _start!,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        if (_end != null && !_end!.isAfter(picked)) {
          _end = picked.add(const Duration(hours: 2));
        }
      });
    }
  }

  Future<void> _pickEnd() async {
    if (_end == null) return;
    final picked = await pickDateTimeWithFiveMinuteSteps(
      context,
      initial: _end!,
      firstDate: _start ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _end = picked);
  }

  Future<void> _submit(double userNtrp) async {
    if (_start == null || _end == null) return;
    if (!_openLocation && _selectedCourt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um local ou marque "local em aberto".')),
      );
      return;
    }
    if (_end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O horário de término deve ser após o início.')),
      );
      return;
    }
    if (!ChallengeNtrpBounds.isValidRange(
      userNtrp: userNtrp,
      minNtrp: _minNtrp,
      maxNtrp: _maxNtrp,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faixa de NTRP inválida para o seu nível.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(challengesRepositoryProvider).updatePublic(
            id: widget.challengeId,
            message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
            openLocation: _openLocation,
            placeId: _openLocation ? null : _selectedCourt?.placeId,
            googlePlaceId: _openLocation ? null : _selectedCourt?.googlePlaceId,
            scheduledStart: _start,
            scheduledEnd: _end,
            minNtrp: _minNtrp,
            maxNtrp: _maxNtrp,
            genderPreference: genderPreferenceFromSet(_genderPrefs),
            professionPreference: _professionController.text.trim().isEmpty
                ? null
                : _professionController.text.trim(),
          );
      bumpChallengesRefresh(ref);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Desafio')),
        body: Center(child: Text(_error!)),
      );
    }

    final userNtrp = ref.watch(authStateProvider).value?.ntrpRating ?? 3.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Desafio Público')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Mensagem (opcional)',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text('Nível procurado'),
          const SizedBox(height: 8),
          ChallengeNtrpRangePicker(
            userNtrp: userNtrp,
            minNtrp: _minNtrp,
            maxNtrp: _maxNtrp,
            onChanged: (values) => setState(() {
              _minNtrp = values.start;
              _maxNtrp = values.end;
            }),
          ),
          const SizedBox(height: 16),
          GenderMultiSelector(
            selected: _genderPrefs,
            onChanged: (g) => setState(() => _genderPrefs = g),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _professionController,
            decoration: const InputDecoration(
              labelText: 'Profissão procurada (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Início'),
            subtitle: Text(_start == null ? '—' : formatDateTimePt(_start!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickStart,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Término'),
            subtitle: Text(_end == null ? '—' : formatDateTimePt(_end!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickEnd,
          ),
          const Divider(),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _openLocation,
            onChanged: (v) => setState(() {
              _openLocation = v ?? false;
              if (_openLocation) _selectedCourt = null;
            }),
            title: const Text('Local em aberto (qualquer local)'),
          ),
          if (!_openLocation) ...[
            const SizedBox(height: 8),
            PlaceSelectField(
              selectedCourt: _selectedCourt,
              onChanged: (court) => setState(() => _selectedCourt = court),
            ),
          ],
          const SizedBox(height: 24),
          LimeButton(
            label: 'Salvar alterações',
            loading: _submitting,
            glow: true,
            onPressed: () => _submit(userNtrp),
          ),
        ],
      ),
    );
  }
}
