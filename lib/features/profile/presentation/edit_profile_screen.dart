import 'dart:io';

import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/profile/providers/profile_feedback_provider.dart';
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
import 'package:conectenis_app/shared/models/user_profile.dart';
import 'package:conectenis_app/shared/models/address_form_data.dart';
import 'package:conectenis_app/shared/widgets/address_form_fields.dart';
import 'package:conectenis_app/shared/widgets/app_card.dart';
import 'package:conectenis_app/shared/widgets/app_toast.dart';
import 'package:conectenis_app/shared/widgets/bottom_action_bar.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/ntrp_rating_picker.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';
import 'package:conectenis_app/shared/widgets/section_label.dart';
import 'package:conectenis_app/shared/widgets/segmented_tabs.dart';
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
      showToast(context, addressError);
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
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      }
    } catch (e) {
      if (mounted) {
        showToast(context, authErrorMessage(e));
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
        showToast(context, 'Voltando a usar Gravatar.');
      }
    } catch (e) {
      if (mounted) showToast(context, authErrorMessage(e));
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
    final t = context.t;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Editar perfil', close: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _saving ? null : _pickAvatar,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: t.accent, width: 3),
                              ),
                              child: _localAvatarPath != null
                                  ? CircleAvatar(
                                      radius: 45,
                                      backgroundImage:
                                          FileImage(File(_localAvatarPath!)),
                                    )
                                  : UserAvatar(
                                      name: user.name,
                                      email: user.email,
                                      avatarUrl: user.avatarUrl,
                                      hasCustomAvatar: user.hasCustomAvatar,
                                      userId: user.id,
                                      radius: 45,
                                    ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: t.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: t.bg, width: 3),
                                ),
                                child: Icon(Symbols.photo_camera_rounded,
                                    size: 16, fill: 1, color: t.onAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (user.hasCustomAvatar && _localAvatarPath == null)
                      Center(
                        child: TextButton(
                          onPressed: _saving ? null : _removeCustomAvatar,
                          child: Text(
                            'Remover foto e usar Gravatar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.accentText,
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            'Sem foto personalizada, exibimos seu Gravatar pelo e-mail.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: t.disabled),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ReadOnlyTile(
                            label: 'Gênero',
                            value: user.gender?.label ?? '-',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ReadOnlyTile(
                            label: 'Nascimento',
                            value: formatDateOfBirth(user.dateOfBirth),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const SectionLabel('Profissão'),
                    const SizedBox(height: 9),
                    TextField(
                      controller: _professionController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ex.: Engenheiro de Software',
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SectionLabel('Endereço'),
                    const SizedBox(height: 9),
                    AddressFormFields(
                      data: _addressData,
                      onChanged: (data) => setState(() => _addressData = data),
                    ),
                    const SizedBox(height: 22),
                    const SectionLabel('Nível NTRP'),
                    const SizedBox(height: 10),
                    NtrpRatingPicker(
                      value: _ntrp,
                      onChanged: (v) => setState(() => _ntrp = v),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        '${ntrpLevelName(_ntrp)} · ${ntrpValueLabel(_ntrp)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: t.accentText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.tintWarn,
                        border: Border.all(
                            color: t.warning.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Symbols.balance_rounded,
                              size: 19, color: t.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mudanças grandes de nível passam por validação da comunidade nas próximas partidas.',
                              style: TextStyle(
                                  fontSize: 12, color: t.muted, height: 1.5),
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
                      onChanged: (i) =>
                          setState(() => _style = PlayStyle.values[i]),
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
          label: 'Salvar alterações',
          loading: _saving,
          glow: true,
          onPressed: _saving ? null : _save,
        ),
      ),
    );
  }
}

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 14,
      color: t.surface2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: t.disabled,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
        ],
      ),
    );
  }
}
