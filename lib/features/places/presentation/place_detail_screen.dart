import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/places/data/places_repository.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/app_switch.dart';
import 'package:conectenis_app/shared/widgets/report_reason_sheet.dart';
import 'package:conectenis_app/shared/widgets/star_rating_input.dart';
import 'package:conectenis_app/shared/utils/plural_pt.dart';
import 'package:conectenis_app/shared/widgets/app_snackbar.dart';
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
  bool _isPublic = true;
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
        _isPublic = place?.isPublic ?? true;
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
    return _place!.isOwner || user.isAdmin;
  }

  Future<void> _saveEdit() async {
    if (_place == null) return;
    final isAdmin = ref.read(authStateProvider).valueOrNull?.isAdmin ?? false;
    setState(() => _busy = true);
    try {
      final updated = await ref.read(placesRepositoryProvider).update(
            id: _place!.id,
            name: _nameController.text.trim(),
            isPublic: isAdmin ? _isPublic : null,
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

  Future<void> _delete() async {
    final place = _place;
    if (place == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir local'),
        content: Text('Excluir "${place.name}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(placesRepositoryProvider).delete(place.id);
      if (mounted) context.pop();
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
        AppSnackBar.showSuccess(context, 'Denúncia enviada com sucesso.');
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
        AppSnackBar.showSuccess(context, 'Avaliação enviada com sucesso.');
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
    final placeDims = place.ratingDimensions;
    final isAdmin = ref.watch(authStateProvider).valueOrNull?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar local' : place.name),
        actions: [
          if (_canEdit && !_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _busy ? null : () => setState(() => _editing = true),
            ),
          if (_canEdit && !_editing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
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
            if (isAdmin) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Local público (visível para todos)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  AppSwitch(
                    value: _isPublic,
                    onChanged: _busy ? null : (v) => setState(() => _isPublic = v),
                  ),
                ],
              ),
            ],
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
                const Icon(Icons.star, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  place.averageRating != null
                      ? '${place.averageRating!.toStringAsFixed(1)} · ${formatAvaliacoesCount(place.ratingsCount)}'
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
            if (placeDims != null) ...[
              if (placeDims.courtQuality != null)
                ListTile(
                  dense: true,
                  title: const Text('Qualidade da quadra (média)'),
                  trailing: Text(placeDims.courtQuality!.toStringAsFixed(1)),
                ),
              if (placeDims.infrastructure != null)
                ListTile(
                  dense: true,
                  title: const Text('Infraestrutura (média)'),
                  trailing: Text(placeDims.infrastructure!.toStringAsFixed(1)),
                ),
            ],
            if (place.recentReviews.isNotEmpty) ...[
              const Divider(height: 32),
              Text('Comentários', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...place.recentReviews.map(
                (review) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(review.author),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (review.courtQualityStars != null)
                          Text('Quadra: ${'★' * review.courtQualityStars!}'),
                        if (review.infrastructureStars != null)
                          Text('Infraestrutura: ${'★' * review.infrastructureStars!}'),
                        Text(
                          review.comment.isEmpty ? '(sem comentário)' : review.comment,
                        ),
                      ],
                    ),
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
