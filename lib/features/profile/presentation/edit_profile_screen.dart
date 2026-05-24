import 'package:conectenis_app/core/theme/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:conectenis_app/shared/widgets/ntrp_rating_picker.dart';

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

  Future<void> _save() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(authStateProvider.notifier).updateProfile(
            user.copyWith(
              profession: _professionController.text.trim(),
              addressLine: _addressController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              ntrpRating: _ntrp,
              playStyle: _style,
            ),
          );
      if (mounted) context.pop();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Sexo'),
            child: Text(user.gender?.label ?? '—'),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Idade'),
            child: Text(user.age?.toString() ?? '—'),
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
