import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/shared/utils/date_time_format.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/features/play_invitations/data/play_invitations_repository.dart';
import 'package:conectenis_app/shared/models/place.dart';

class CreateInvitationScreen extends ConsumerStatefulWidget {
  const CreateInvitationScreen({super.key, required this.inviteeId});

  final int inviteeId;

  @override
  ConsumerState<CreateInvitationScreen> createState() => _CreateInvitationScreenState();
}

class _CreateInvitationScreenState extends ConsumerState<CreateInvitationScreen> {
  final _messageController = TextEditingController();
  DateTime _scheduledAt = roundToFiveMinutes(DateTime.now().add(const Duration(hours: 2)));
  Place? _selectedPlace;
  List<Place> _places = [];
  bool _loadingPlaces = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() => _loadingPlaces = true);
    try {
      double lat = MockData.centerLat;
      double lng = MockData.centerLng;
      try {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}
      final list = await ref.read(placesRepositoryProvider).nearby(lat: lat, lng: lng);
      setState(() {
        _places = list;
        _selectedPlace = list.isNotEmpty ? list.first : null;
        _loadingPlaces = false;
      });
    } catch (e) {
      setState(() => _loadingPlaces = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _pickDateTime() async {
    final picked = await pickDateTimeWithFiveMinuteSteps(
      context,
      initial: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledAt = picked);
  }

  Future<void> _addNewPlace() async {
    final place = await context.push<Place>('/places/new');
    if (place != null) {
      setState(() {
        _places = [place, ..._places];
        _selectedPlace = place;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ou cadastre um local.')),
      );
      return;
    }
    if (_scheduledAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma data e hora no futuro.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final inv = await ref.read(playInvitationsRepositoryProvider).create(
            inviteeId: widget.inviteeId,
            placeId: _selectedPlace!.id,
            scheduledAt: _scheduledAt,
            message: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          );
      if (!mounted) return;
      context.go('/invitations/${inv.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Convidar para jogar')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data e hora'),
            subtitle: Text(_formatDateTime(_scheduledAt)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDateTime,
          ),
          const Divider(),
          Text('Local', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_loadingPlaces)
            const Center(child: CircularProgressIndicator())
          else if (_places.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nenhum local por perto. Cadastre um novo.'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addNewPlace,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Cadastrar local'),
                ),
              ],
            )
          else ...[
            DropdownButtonFormField<Place>(
              initialValue: _selectedPlace,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _places
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (${p.subtitle})'),
                    ),
                  )
                  .toList(),
              onChanged: (p) => setState(() => _selectedPlace = p),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addNewPlace,
              icon: const Icon(Icons.add),
              label: const Text('Novo local'),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLength: 500,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Mensagem (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar convite'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) => formatDateTimePt(dt);
}
