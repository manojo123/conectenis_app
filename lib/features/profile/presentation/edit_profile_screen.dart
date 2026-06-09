import 'dart:io';

import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/profile/providers/profile_feedback_provider.dart';
import 'package:conectenis_app/shared/widgets/app_snackbar.dart';
import 'package:conectenis_app/shared/utils/avatar_picker.dart';
import 'package:conectenis_app/shared/utils/date_of_birth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';
import 'package:conectenis_app/shared/models/address_form_data.dart';
import 'package:conectenis_app/shared/widgets/address_form_fields.dart';
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
  AddressFormData _addressData = const AddressFormData();
  double _ntrp = 3.0;
  PlayStyle _style = PlayStyle.both;
  bool _saving = false;
  bool _initialized = false;
  String? _localAvatarPath;

  @override
  void dispose() {
    _professionController.dispose();
    super.dispose();
  }

  void _initFromUser(UserProfile user) {
    if (_initialized) return;
    _professionController.text = user.profession ?? '';
    _addressData = initialAddressFormData(user);
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

    final addressError = _addressData.validate();
    if (addressError != null) {
      AppSnackBar.showDanger(context, addressError);
      return;
    }

    setState(() => _saving = true);
    try {
      if (_localAvatarPath != null) {
        await ref.read(authStateProvider.notifier).uploadAvatar(_localAvatarPath!);
      }

      final latest = ref.read(authStateProvider).value ?? user;
      await ref.read(authStateProvider.notifier).updateProfile(
            _addressData.applyTo(
              latest.copyWith(
                profession: _professionController.text.trim(),
                ntrpRating: _ntrp,
                playStyle: _style,
                profileComplete: true,
              ),
            ),
          );
      if (mounted) {
        ref.read(profileUpdatedNoticeProvider.notifier).state = true;
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showDanger(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeCustomAvatar() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || !user.hasCustomAvatar) return;

    setState(() => _saving = true);
    try {
      await ref.read(authStateProvider.notifier).removeCustomAvatar();
      if (mounted) {
        setState(() => _localAvatarPath = null);
        AppSnackBar.showSuccess(context, 'Voltando a usar Gravatar.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showDanger(context, e.toString());
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
                  : UserAvatar(
                      name: user.name,
                      email: user.email,
                      avatarUrl: user.avatarUrl,
                      hasCustomAvatar: user.hasCustomAvatar,
                      radius: 52,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(onPressed: _saving ? null : _pickAvatar, child: const Text('Enviar foto personalizada')),
          ),
          if (user.hasCustomAvatar && _localAvatarPath == null)
            Center(
              child: TextButton(
                onPressed: _saving ? null : _removeCustomAvatar,
                child: const Text('Remover foto e usar Gravatar'),
              ),
            ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Sem foto personalizada, exibimos seu Gravatar pelo e-mail.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ),
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
          AddressFormFields(
            data: _addressData,
            onChanged: (data) => setState(() => _addressData = data),
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
