import 'dart:io';

import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/shared/utils/avatar_picker.dart';
import 'package:conectenis_app/shared/utils/date_of_birth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/data/auth_repository.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/gender_selector.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/ntrp_rating_picker.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _professionController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'SP');
  final _addressController = TextEditingController();
  DateTime? _dateOfBirth;
  double _ntrp = 3.0;
  Gender _gender = Gender.male;
  PlayStyle _style = PlayStyle.both;
  String? _avatarPath;
  bool _saving = false;

  @override
  void dispose() {
    _professionController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final path = await pickAvatarImagePath(context);
    if (path != null) setState(() => _avatarPath = path);
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10, now.month, now.day),
      helpText: 'Data de nascimento',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe sua data de nascimento')),
      );
      return;
    }
    final age = ageFromDateOfBirth(_dateOfBirth);
    if (age == null || age < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma data de nascimento válida')),
      );
      return;
    }
    if (_avatarPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inclua uma foto obrigatória')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      var avatarUrl = user.avatarUrl;
      if (_avatarPath != null) {
        avatarUrl = await ref.read(authRepositoryProvider).uploadAvatar(_avatarPath!);
      }

      await ref.read(authStateProvider.notifier).updateProfile(
            user.copyWith(
              dateOfBirth: _dateOfBirth,
              ntrpRating: _ntrp,
              gender: _gender,
              profession: _professionController.text.trim(),
              addressLine: _addressController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              playStyle: _style,
              avatarUrl: avatarUrl,
              profileComplete: true,
            ),
          );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Crie Seu Perfil')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 52,
                backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                child: _avatarPath == null ? const Icon(Icons.add_a_photo, size: 36) : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Incluir Foto Obrigatória', textAlign: TextAlign.center),
          TextButton(onPressed: _pickAvatar, child: const Text('Tirar foto ou escolher da galeria')),
          const SizedBox(height: 8),
          Text('Olá, ${user?.name ?? ''}!'),
          const SizedBox(height: 16),
          const Text('Sexo'),
          GenderSelector(
            value: _gender,
            onChanged: (g) {
              if (g != null) setState(() => _gender = g);
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDateOfBirth,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data de nascimento',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _dateOfBirth == null ? 'Selecionar' : formatDateOfBirth(_dateOfBirth),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _professionController, decoration: const InputDecoration(labelText: 'Profissão')),
          const SizedBox(height: 12),
          TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Endereço')),
          const SizedBox(height: 12),
          TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'Cidade')),
          const SizedBox(height: 12),
          TextField(controller: _stateController, decoration: const InputDecoration(labelText: 'Estado (UF)')),
          const SizedBox(height: 16),
          const Text('Nível de Jogo (NTRP)'),
          NtrpRatingPicker(value: _ntrp, onChanged: (v) => setState(() => _ntrp = v)),
          const SizedBox(height: 16),
          DropdownButtonFormField<PlayStyle>(
            initialValue: _style,
            decoration: const InputDecoration(labelText: 'Estilo de jogo'),
            items: PlayStyle.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
            onChanged: (v) => setState(() => _style = v!),
          ),
          const SizedBox(height: 32),
          LimeButton(label: 'Salvar perfil', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
