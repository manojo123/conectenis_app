import 'dart:io';

import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/shared/utils/avatar_picker.dart';
import 'package:conectenis_app/shared/utils/date_of_birth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';
import 'package:conectenis_app/shared/models/address_form_data.dart';
import 'package:conectenis_app/shared/widgets/address_form_fields.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';
import 'package:conectenis_app/shared/widgets/gender_selector.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/ntrp_rating_picker.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _professionController = TextEditingController();
  AddressFormData _addressData = const AddressFormData();
  DateTime? _dateOfBirth;
  double _ntrp = 3.0;
  Gender _gender = Gender.male;
  PlayStyle _style = PlayStyle.both;
  String? _avatarPath;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromContext());
  }

  void _initFromContext() {
    if (_initialized) return;
    final user = ref.read(authStateProvider).value;

    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      if (user.dateOfBirth != null) _dateOfBirth = user.dateOfBirth;
      if (user.gender != null) _gender = user.gender!;
      _ntrp = user.ntrpRating;
      _style = user.playStyle;
      if (user.profession != null) _professionController.text = user.profession!;
      _addressData = initialAddressFormData(user);
    }

    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _professionController.dispose();
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

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu nome')),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um e-mail válido')),
      );
      return;
    }

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
    final addressError = _addressData.validate();
    if (addressError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(addressError)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_avatarPath != null) {
        await ref.read(authStateProvider.notifier).uploadAvatar(_avatarPath!);
      }

      final currentUser = ref.read(authStateProvider).value ?? user;

      await ref.read(authStateProvider.notifier).updateProfile(
            _addressData.applyTo(
              currentUser.copyWith(
                name: name,
                email: email,
                dateOfBirth: _dateOfBirth,
                ntrpRating: _ntrp,
                gender: _gender,
                profession: _professionController.text.trim(),
                playStyle: _style,
                profileComplete: true,
              ),
            ),
          );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildAvatar(UserProfile? user) {
    if (_avatarPath != null) {
      return CircleAvatar(
        radius: 52,
        backgroundImage: FileImage(File(_avatarPath!)),
      );
    }
    return UserAvatar(
      name: user?.name ?? _nameController.text,
      email: user?.email ?? _emailController.text,
      avatarUrl: user?.avatarUrl,
      hasCustomAvatar: user?.hasCustomAvatar ?? false,
      radius: 52,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final greetingName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (user?.name ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('Crie Seu Perfil')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: _buildAvatar(user),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Foto de perfil (opcional)',
            textAlign: TextAlign.center,
          ),
          const Text(
            'Sem foto, usamos seu Gravatar pelo e-mail.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          TextButton(onPressed: _pickAvatar, child: const Text('Tirar foto ou escolher da galeria')),
          if (greetingName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Olá, $greetingName!'),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
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
          LimeButton(
            label: 'Salvar perfil',
            loading: _saving,
            glow: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
