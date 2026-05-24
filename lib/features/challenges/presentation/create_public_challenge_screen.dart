import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/challenges/data/challenges_repository.dart';
import 'package:conectenis_app/features/challenges/providers/challenges_refresh_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/utils/date_time_format.dart';
import 'package:conectenis_app/shared/widgets/gender_multi_selector.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/ntrp_rating_picker.dart';
import 'package:conectenis_app/shared/widgets/place_select_field.dart';

class CreatePublicChallengeScreen extends ConsumerStatefulWidget {
  const CreatePublicChallengeScreen({super.key});

  @override
  ConsumerState<CreatePublicChallengeScreen> createState() => _CreatePublicChallengeScreenState();
}

class _CreatePublicChallengeScreenState extends ConsumerState<CreatePublicChallengeScreen> {
  final Set<ChallengeFormat> _formats = {ChallengeFormat.singles};
  double _minNtrp = 3.0;
  final double _maxNtrp = 4.0;
  Set<Gender> _genderPrefs = {};
  DateTime _start = roundToFiveMinutes(DateTime.now().add(const Duration(days: 2)));
  bool _openLocation = false;
  Place? _selectedPlace;
  bool _submitting = false;

  void _toggleFormat(ChallengeFormat format) {
    setState(() {
      if (_formats.contains(format)) {
        if (_formats.length > 1) _formats.remove(format);
      } else {
        _formats.add(format);
      }
    });
  }

  Future<void> _pickDateTime() async {
    final picked = await pickDateTimeWithFiveMinuteSteps(
      context,
      initial: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _submit() async {
    if (_formats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione simples e/ou duplas.')),
      );
      return;
    }
    if (!_openLocation && _selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um local ou marque "local em aberto".')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(challengesRepositoryProvider);
      for (final format in _formats) {
        await repo.createPublic(
          format: format,
          scheduledStart: _start,
          openLocation: _openLocation,
          placeId: _openLocation ? null : _selectedPlace?.id,
          minNtrp: _minNtrp,
          maxNtrp: _maxNtrp,
          genderPreference: genderPreferenceFromSet(_genderPrefs),
        );
      }
      bumpChallengesRefresh(ref);
      if (!mounted) return;
      context.go('/challenges');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Desafio Público')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          const Text('Nível procurado'),
          NtrpRatingPicker(value: _minNtrp, onChanged: (v) => setState(() => _minNtrp = v)),
          const SizedBox(height: 8),
          GenderMultiSelector(
            selected: _genderPrefs,
            onChanged: (g) => setState(() => _genderPrefs = g),
          ),
          const SizedBox(height: 16),
          const Text('Modalidade'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ChallengeFormat.values.map((format) {
              final selected = _formats.contains(format);
              return FilterChip(
                label: Text(format.label),
                selected: selected,
                onSelected: (_) => _toggleFormat(format),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data e hora'),
            subtitle: Text(formatDateTimePt(_start)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDateTime,
          ),
          const Divider(),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _openLocation,
            onChanged: (v) => setState(() {
              _openLocation = v ?? false;
              if (_openLocation) _selectedPlace = null;
            }),
            title: const Text('Local em aberto (qualquer local)'),
          ),
          if (!_openLocation) ...[
            const SizedBox(height: 8),
            PlaceSelectField(
              selectedPlace: _selectedPlace,
              onChanged: (place) => setState(() => _selectedPlace = place),
            ),
          ],
          const SizedBox(height: 24),
          LimeButton(label: 'Confirmar envio', loading: _submitting, onPressed: _submit),
        ],
      ),
    );
  }
}
