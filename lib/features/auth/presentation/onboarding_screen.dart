import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ageController = TextEditingController();
  SkillLevel _skill = SkillLevel.intermediate;
  PlayStyle _style = PlayStyle.both;
  String? _avatarPath;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma idade válida')),
      );
      return;
    }

    await ref.read(authStateProvider.notifier).updateProfile(
          user.copyWith(
            age: age,
            skillLevel: _skill,
            playStyle: _style,
            avatarUrl: _avatarPath,
            profileComplete: true,
          ),
        );
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Seu perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Olá, ${user?.name ?? ''}! Complete seu perfil para encontrar parceiros.'),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () async {
                final file = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (file != null) setState(() => _avatarPath = file.path);
              },
              child: CircleAvatar(
                radius: 44,
                backgroundImage:
                    _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                child: _avatarPath == null ? const Icon(Icons.camera_alt, size: 32) : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Idade'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<SkillLevel>(
            initialValue: _skill,
            decoration: const InputDecoration(labelText: 'Nível'),
            items: SkillLevel.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) => setState(() => _skill = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<PlayStyle>(
            initialValue: _style,
            decoration: const InputDecoration(labelText: 'Estilo de jogo'),
            items: PlayStyle.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) => setState(() => _style = v!),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _save, child: const Text('Continuar')),
        ],
      ),
    );
  }
}
