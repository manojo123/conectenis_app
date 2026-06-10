import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/core/storage/profile_storage.dart';
import 'package:conectenis_app/features/auth/data/auth_repository.dart';
import 'package:conectenis_app/features/location/location_permission_provider.dart';
import 'package:conectenis_app/features/location/location_permission_service.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

enum UserLocationSyncStatus {
  synced,
  permissionDenied,
  serviceDisabled,
  unavailable,
}

class UserLocationSyncResult {
  const UserLocationSyncResult({
    required this.status,
    this.profile,
  });

  final UserLocationSyncStatus status;
  final UserProfile? profile;

  bool get isSuccess => status == UserLocationSyncStatus.synced;
}

final userLocationServiceProvider = Provider<UserLocationService>((ref) {
  return UserLocationService(
    authRepository: ref.watch(authRepositoryProvider),
    permissionService: ref.watch(locationPermissionServiceProvider),
    profileStorage: ref.watch(profileStorageProvider),
  );
});

class UserLocationService {
  UserLocationService({
    required AuthRepository authRepository,
    required LocationPermissionService permissionService,
    required ProfileStorage profileStorage,
  })  : _authRepository = authRepository,
        _permissionService = permissionService,
        _profileStorage = profileStorage;

  final AuthRepository _authRepository;
  final LocationPermissionService _permissionService;
  final ProfileStorage _profileStorage;

  /// Reads GPS and persists coordinates on the backend.
  Future<UserLocationSyncResult> syncCurrentLocation() async {
    var access = await _permissionService.checkStatus();
    if (access == LocationAccessStatus.denied) {
      access = await _permissionService.requestPermission();
    }
    switch (access) {
      case LocationAccessStatus.serviceDisabled:
        return const UserLocationSyncResult(
          status: UserLocationSyncStatus.serviceDisabled,
        );
      case LocationAccessStatus.denied:
      case LocationAccessStatus.deniedForever:
      case LocationAccessStatus.unknown:
        return const UserLocationSyncResult(
          status: UserLocationSyncStatus.permissionDenied,
        );
      case LocationAccessStatus.granted:
        break;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (Env.useMockApi) {
        final current = await _profileStorage.read();
        if (current == null) {
          return const UserLocationSyncResult(
            status: UserLocationSyncStatus.unavailable,
          );
        }
        final updated = current.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        await _profileStorage.write(updated);
        return UserLocationSyncResult(
          status: UserLocationSyncStatus.synced,
          profile: updated,
        );
      }

      final profile = await _authRepository.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      return UserLocationSyncResult(
        status: UserLocationSyncStatus.synced,
        profile: profile,
      );
    } catch (_) {
      return const UserLocationSyncResult(
        status: UserLocationSyncStatus.unavailable,
      );
    }
  }
}
