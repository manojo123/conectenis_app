import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/report_reason_sheet.dart';
import 'package:conectenis_app/shared/widgets/star_rating_input.dart';
import 'package:conectenis_app/shared/widgets/static_place_map.dart';

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
  final _commentController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
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

  bool get _canEdit {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || _place == null) return false;
    return _place!.createdByUserId == user.id || user.isAdmin;
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
      await ref.read(placesRepositoryProvider).report(
            id: _place!.id,
            reason: PlaceReportReason.fromValue(result.reason),
            details: result.details,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Denúncia enviada com sucesso.')),
        );
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
      await ref.read(placesRepositoryProvider).rate(
            id: _place!.id,
            stars: _rateStars,
            comment: _commentController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avaliação enviada com sucesso.')),
        );
        _commentController.clear();
        _rateStars = 0;
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
          if (_canEdit && !_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, screenBottomInset(context) + 24),
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
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  place.averageRating != null
                      ? '${place.averageRating!.toStringAsFixed(1)} · ${place.ratingsCount} avaliação(ões)'
                      : 'Sem avaliações ainda',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(place.subtitle),
            const SizedBox(height: 12),
            StaticPlaceMap(latitude: place.latitude, longitude: place.longitude),
            const Divider(height: 32),
            Text('Avaliar local', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            StarRatingInput(
              value: _rateStars,
              onChanged: (v) => setState(() => _rateStars = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentário (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _busy || _rateStars < 1 ? null : _rate,
              child: const Text('Enviar avaliação'),
            ),
            if (place.recentReviews.isNotEmpty) ...[
              const Divider(height: 32),
              Text('Comentários', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...place.recentReviews.map(
                (review) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(review.author),
                    subtitle: Text(review.comment.isEmpty ? '(sem comentário)' : review.comment),
                    trailing: Text('★' * review.stars),
                  ),
                ),
              ),
            ],
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
