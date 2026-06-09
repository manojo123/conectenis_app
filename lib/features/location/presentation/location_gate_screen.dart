import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/core/theme/layout.dart';
import 'package:conectenis_app/features/location/location_permission_provider.dart';
import 'package:conectenis_app/features/location/location_permission_service.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationGateScreen extends ConsumerWidget {
  const LocationGateScreen({super.key, required this.status});

  final LocationAccessStatus status;

  String get _title {
    switch (status) {
      case LocationAccessStatus.serviceDisabled:
        return 'Ative a localização do dispositivo';
      case LocationAccessStatus.deniedForever:
        return 'Permissão de localização bloqueada';
      case LocationAccessStatus.denied:
      case LocationAccessStatus.unknown:
        return 'Localização necessária';
      case LocationAccessStatus.granted:
        return '';
    }
  }

  String get _message {
    switch (status) {
      case LocationAccessStatus.serviceDisabled:
        return 'O GPS precisa estar ativo para encontrar jogadores e quadras na sua região.';
      case LocationAccessStatus.deniedForever:
        return 'Sem acesso à localização, o matchmaking regional e o mapa ficam indisponíveis. '
            'Abra as configurações do app e permita a localização.';
      case LocationAccessStatus.denied:
      case LocationAccessStatus.unknown:
        return 'O ConecTenis usa sua localização para matchmaking regional, mapa e jogadores próximos. '
            'Permita o acesso para usar a Página Inicial e o Mapa.';
      case LocationAccessStatus.granted:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requesting = ref.watch(locationAccessStatusProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 32, 24, screenBottomInset(context) + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.location_on, size: 72, color: AppColors.lime),
              const SizedBox(height: 24),
              Text(
                _title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (status == LocationAccessStatus.denied ||
                  status == LocationAccessStatus.unknown)
                LimeButton(
                  label: 'Permitir localização',
                  loading: requesting,
                  onPressed: requesting
                      ? null
                      : () => ref
                          .read(locationAccessStatusProvider.notifier)
                          .requestPermission(),
                ),
              if (status == LocationAccessStatus.serviceDisabled) ...[
                LimeButton(
                  label: 'Abrir configurações de GPS',
                  loading: requesting,
                  onPressed: requesting
                      ? null
                      : () => ref
                          .read(locationPermissionServiceProvider)
                          .openLocationSettings(),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: requesting
                      ? null
                      : () => ref
                          .read(locationAccessStatusProvider.notifier)
                          .refresh(),
                  child: const Text('Verificar novamente'),
                ),
              ],
              if (status == LocationAccessStatus.deniedForever) ...[
                LimeButton(
                  label: 'Abrir configurações do app',
                  onPressed: () => ref
                      .read(locationPermissionServiceProvider)
                      .openAppSettings(),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: requesting
                      ? null
                      : () => ref
                          .read(locationAccessStatusProvider.notifier)
                          .refresh(),
                  child: const Text('Verificar novamente'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
