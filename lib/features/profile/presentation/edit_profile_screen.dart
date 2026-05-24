import 'dart:io';

import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/data/auth_repository.dart';
import 'package:conectenis_app/features/profile/providers/profile_feedback_provider.dart';
import 'package:conectenis_app/shared/utils/avatar_picker.dart';
import 'package:conectenis_app/shared/utils/date_of_birth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/ntrp_rating_picker.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _professionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  double _ntrp = 3.0;
  PlayStyle _style = PlayStyle.both;
  bool _saving = false;
  bool _initialized = false;
  String? _localAvatarPath;

  @override
  void dispose() {
    _professionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _initFromUser(UserProfile user) {
    if (_initialized) return;
    _professionController.text = user.profession ?? '';
    _addressController.text = user.addressLine ?? '';
    _cityController.text = user.city ?? '';
    _stateController.text = user.state ?? '';
    _ntrp = user.ntrpRating;
    _style = user.playStyle;
    _initialized = true;
  }

  Future<void> _pickAvatar() async {
    final path = await pickAvatarImagePath(context);
    if (path != null) setState(() => _localAvatarPath = path);
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      var avatarUrl = user.avatarUrl;
      if (_localAvatarPath != null) {
        avatarUrl = await ref.read(authRepositoryProvider).uploadAvatar(_localAvatarPath!);
      }

      await ref.read(authStateProvider.notifier).updateProfile(
            user.copyWith(
              profession: _professionController.text.trim(),
              addressLine: _addressController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              ntrpRating: _ntrp,
              playStyle: _style,
              avatarUrl: avatarUrl,
              profileComplete: true,
            ),
          );
      if (mounted) {
        ref.read(profileUpdatedNoticeProvider.notifier).state = true;
        context.go('/profile');
      }
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
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _initFromUser(user);

    final displayAvatar = _localAvatarPath ?? user.avatarUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: _localAvatarPath != null
                  ? CircleAvatar(
                      radius: 52,
                      backgroundImage: FileImage(File(_localAvatarPath!)),
                    )
                  : UserAvatar(name: user.name, avatarUrl: displayAvatar, radius: 52),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(onPressed: _pickAvatar, child: const Text('Trocar foto')),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Sexo',
              enabled: false,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Text(user.gender?.label ?? '—'),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Data de nascimento',
              enabled: false,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Text(formatDateOfBirth(user.dateOfBirth)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _professionController,
            decoration: const InputDecoration(labelText: 'Profissão'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Endereço'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'Cidade'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stateController,
            decoration: const InputDecoration(labelText: 'Estado (UF)'),
          ),
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
          LimeButton(label: 'Salvar alterações', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
