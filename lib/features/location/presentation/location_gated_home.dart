import 'package:conectenis_app/features/location/location_permission_provider.dart';
import 'package:conectenis_app/features/location/location_permission_service.dart';
import 'package:conectenis_app/features/location/presentation/location_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationGatedHome extends ConsumerStatefulWidget {
  const LocationGatedHome({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LocationGatedHome> createState() => _LocationGatedHomeState();
}

class _LocationGatedHomeState extends ConsumerState<LocationGatedHome>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationAccessStatusProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(locationAccessStatusProvider);

    return statusAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => LocationGateScreen(status: LocationAccessStatus.denied),
      data: (status) {
        if (status == LocationAccessStatus.granted) {
          return widget.child;
        }
        return LocationGateScreen(status: status);
      },
    );
  }
}
