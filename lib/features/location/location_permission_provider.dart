import 'package:conectenis_app/features/location/location_permission_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationPermissionServiceProvider =
    Provider<LocationPermissionService>((ref) => LocationPermissionService());

final locationAccessStatusProvider =
    AsyncNotifierProvider<LocationAccessNotifier, LocationAccessStatus>(
  LocationAccessNotifier.new,
);

class LocationAccessNotifier extends AsyncNotifier<LocationAccessStatus> {
  @override
  Future<LocationAccessStatus> build() async {
    return ref.read(locationPermissionServiceProvider).checkStatus();
  }

  Future<LocationAccessStatus> refresh() async {
    state = const AsyncLoading();
    final status = await ref.read(locationPermissionServiceProvider).checkStatus();
    state = AsyncData(status);
    return status;
  }

  Future<LocationAccessStatus> requestPermission() async {
    state = const AsyncLoading();
    final status =
        await ref.read(locationPermissionServiceProvider).requestPermission();
    state = AsyncData(status);
    return status;
  }
}
