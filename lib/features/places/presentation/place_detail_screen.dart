import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/report_reason_sheet.dart';
import 'package:conectenis_app/shared/widgets/star_rating_input.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({super.key, required this.placeId});

  final int placeId;

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  Place? _place;
  bool _loading = true;
  String? _error;
  bool _editing = false;
  bool _busy = false;
  int _rateStars = 0;

  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final place = await ref.read(placesRepositoryProvider).byId(widget.placeId);
      setState(() {
        _place = place;
        _nameController.text = place?.name ?? '';
        _loading = false;
        if (place == null) _error = 'Local não encontrado';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = authErrorMessage(e);
      });
    }
  }

  bool get _isCreator {
    final userId = ref.read(authStateProvider).valueOrNull?.id;
    return userId != null && _place?.createdByUserId == userId;
  }

  Future<void> _saveEdit() async {
    if (_place == null) return;
    setState(() => _busy = true);
    try {
      final updated = await ref.read(placesRepositoryProvider).update(
            id: _place!.id,
            name: _nameController.text.trim(),
          );
      setState(() {
        _place = updated;
        _editing = false;
        _busy = false;
      });
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _report() async {
    final result = await showReportReasonSheet(
      context: context,
      title: 'Reportar local',
      reasons: PlaceReportReason.values
          .map((r) => (value: r.value, label: r.label))
          .toList(),
    );
    if (result == null || _place == null) return;
    setState(() => _busy = true);
    try {
      final msg = await ref.read(placesRepositoryProvider).report(
            id: _place!.id,
            reason: PlaceReportReason.fromValue(result.reason),
            details: result.details,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rate() async {
    if (_place == null || _rateStars < 1) return;
    setState(() => _busy = true);
    try {
      final msg = await ref.read(placesRepositoryProvider).rate(
            id: _place!.id,
            stars: _rateStars,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    if (_error != null || _place == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: _error ?? 'Erro', onRetry: _load),
      );
    }

    final place = _place!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar local' : place.name),
        actions: [
          if (_isCreator && !_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_editing) ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => setState(() => _editing = false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _saveEdit,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (place.averageRating != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${place.averageRating!.toStringAsFixed(1)} (${place.ratingsCount} avaliações)',
                  ),
                ],
              )
            else
              Text('Sem avaliações ainda', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(place.subtitle),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}',
                ),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.map),
              label: const Text('Abrir no mapa'),
            ),
            const Divider(height: 32),
            const Text('Avaliar local'),
            const Text(
              'Disponível após um jogo realizado neste local.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            StarRatingInput(
              value: _rateStars,
              onChanged: (v) => setState(() => _rateStars = v),
            ),
            FilledButton.tonal(
              onPressed: _busy || _rateStars < 1 ? null : _rate,
              child: const Text('Enviar avaliação'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _report,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Reportar local'),
            ),
          ],
        ],
      ),
    );
  }
}
