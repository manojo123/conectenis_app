import 'dart:io';

import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/shared/utils/avatar_picker.dart';
import 'package:conectenis_app/shared/utils/date_of_birth.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/address_form_data.dart';
import 'package:conectenis_app/shared/widgets/address_form_fields.dart';
import 'package:conectenis_app/shared/widgets/app_card.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/bottom_action_bar.dart';
import 'package:conectenis_app/shared/widgets/chip_row.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/ntrp_rating_picker.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/section_label.dart';
import 'package:conectenis_app/shared/widgets/segmented_tabs.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _totalSteps = 3;

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
  int _step = 1;

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

  bool _validateStep(int step) {
    switch (step) {
      case 1:
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        if (name.isEmpty) {
          showToast(context, 'Informe seu nome');
          return false;
        }
        if (email.isEmpty || !email.contains('@')) {
          showToast(context, 'Informe um e-mail válido');
          return false;
        }
        if (_dateOfBirth == null) {
          showToast(context, 'Informe sua data de nascimento');
          return false;
        }
        final age = ageFromDateOfBirth(_dateOfBirth);
        if (age == null || age < 10) {
          showToast(context, 'Informe uma data de nascimento válida');
          return false;
        }
        return true;
      case 2:
        final addressError = _addressData.validate();
        if (addressError != null) {
          showToast(context, addressError);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep(_step)) return;
    if (_step < _totalSteps) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      if (_avatarPath != null) {
        await ref.read(authStateProvider.notifier).uploadAvatar(_avatarPath!);
      }

      final currentUser = ref.read(authStateProvider).value ?? user;

      await ref.read(authStateProvider.notifier).updateProfile(
            _addressData.applyTo(
              currentUser.copyWith(
                name: _nameController.text.trim(),
                email: _emailController.text.trim(),
                dateOfBirth: _dateOfBirth,
                ntrpRating: _ntrp,
                gender: _gender,
                profession: _professionController.text.trim(),
                playStyle: _style,
                profileComplete: true,
              ),
            ),
          );
      if (mounted) {
        showToast(context, 'Perfil criado! Bem-vindo ao ConecTênis.');
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        showToast(context, authErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    final title = switch (_step) {
      1 => 'Sobre você',
      2 => 'Onde você joga',
      _ => 'Seu nível de jogo',
    };
    final subtitle = switch (_step) {
      1 => 'Foto, gênero e idade — usados no matchmaking.',
      2 => 'Seu endereço define seus rankings e desafios próximos.',
      _ => 'O NTRP equilibra seus desafios. Seja honesto!',
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(t),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: t.muted, height: 1.5),
                    ),
                    const SizedBox(height: 26),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.06, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: switch (_step) {
                          1 => _stepAbout(t),
                          2 => _stepAddress(t),
                          _ => _stepLevel(t),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LimeButton(
          label: _step < _totalSteps ? 'Continuar' : 'Concluir cadastro',
          glow: true,
          loading: _saving,
          onPressed: _saving ? null : _next,
        ),
      ),
    );
  }

  Widget _header(AppTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          if (_step > 1) ...[
            CircleIconButton(
              icon: Symbols.arrow_back_rounded,
              onTap: () => setState(() => _step--),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Etapa $_step de $_totalSteps',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.muted,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(color: t.surface2),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.centerLeft,
                          widthFactor: _step / _totalSteps,
                          child: Container(color: t.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepAbout(AppTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
      Center(
        child: GestureDetector(
          onTap: _pickAvatar,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.accent, width: 3),
                ),
                child: _avatarPath != null
                    ? CircleAvatar(
                        radius: 48,
                        backgroundImage: FileImage(File(_avatarPath!)),
                      )
                    : UserAvatar(
                        name: _nameController.text.isNotEmpty
                            ? _nameController.text
                            : (ref.read(authStateProvider).value?.name ?? ''),
                        email: ref.read(authStateProvider).value?.email,
                        avatarUrl: ref.read(authStateProvider).value?.avatarUrl,
                        hasCustomAvatar:
                            ref.read(authStateProvider).value?.hasCustomAvatar ??
                                false,
                        userId: ref.read(authStateProvider).value?.id,
                        radius: 48,
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.bg, width: 3),
                  ),
                  child: Icon(Symbols.photo_camera_rounded,
                      size: 17, fill: 1, color: t.onAccent),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          'Sem foto, usamos seu Gravatar pelo e-mail.',
          style: TextStyle(fontSize: 12, color: t.disabled),
        ),
      ),
      const SizedBox(height: 22),
      TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Nome completo',
          prefixIcon: Icon(Symbols.person_rounded, size: 20),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: 'E-mail',
          prefixIcon: Icon(Symbols.mail_rounded, size: 20),
        ),
      ),
      const SizedBox(height: 22),
      const SectionLabel('Gênero'),
      const SizedBox(height: 10),
      ChoiceChipRow(
        options: Gender.values.map((g) => g.label).toList(),
        selectedIndex: Gender.values.indexOf(_gender),
        onSelected: (i) => setState(() => _gender = Gender.values[i]),
      ),
      const SizedBox(height: 22),
      const SectionLabel('Data de nascimento'),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _pickDateOfBirth,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: t.inputBg,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Symbols.calendar_month_rounded, size: 20, color: t.muted),
              const SizedBox(width: 10),
              Text(
                _dateOfBirth == null
                    ? 'Selecionar'
                    : formatDateOfBirth(_dateOfBirth),
                style: TextStyle(
                  fontSize: 15,
                  color: _dateOfBirth == null ? t.muted : t.text,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      SectionLabel(
        'Profissão',
        trailing: Text(
          '(opcional)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: t.disabled,
          ),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _professionController,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Ex.: Engenheiro de Software',
        ),
      ),
      ],
    );
  }

  Widget _stepAddress(AppTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AddressFormFields(
          data: _addressData,
          onChanged: (data) => setState(() => _addressData = data),
        ),
        const SizedBox(height: 18),
        AppCard(
          padding: const EdgeInsets.all(14),
          radius: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Symbols.shield_rounded, size: 22, color: t.accentText),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sua localização exata nunca é exibida. Outros jogadores veem apenas o bairro e a distância aproximada.',
                  style: TextStyle(fontSize: 13, color: t.muted, height: 1.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepLevel(AppTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: NtrpRatingPicker(
            value: _ntrp,
            size: 46,
            showScale: false,
            onChanged: (v) => setState(() => _ntrp = v),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              ntrpValueLabel(_ntrp),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: t.accentText,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'NTRP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: t.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ntrpLevelName(_ntrp),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                ntrpLevelDescription(_ntrp),
                style: TextStyle(fontSize: 13, color: t.muted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.tintWarn,
            border: Border.all(color: t.warning.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Symbols.balance_rounded, size: 22, color: t.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Seu nível é validado pela comunidade após as primeiras partidas. Exagerar só rende derrotas de 6–0.',
                  style: TextStyle(fontSize: 13, color: t.muted, height: 1.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionLabel('Preferência de jogo'),
        const SizedBox(height: 10),
        SegmentedTabs(
          labels: PlayStyle.values.map((s) => s.label).toList(),
          index: PlayStyle.values.indexOf(_style),
          onChanged: (i) => setState(() => _style = PlayStyle.values[i]),
        ),
      ],
    );
  }
}
