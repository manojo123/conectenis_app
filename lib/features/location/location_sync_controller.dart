import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/features/auth/data/auth_repository.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/location/user_location_service.dart';

final locationSyncControllerProvider = Provider<LocationSyncController>((ref) {
  return LocationSyncController(ref);
});

/// Deduplicates GPS reads and PUT /user/location calls across tabs.
class LocationSyncController {
  LocationSyncController(this._ref);

  final Ref _ref;
  Future<UserLocationSyncResult?>? _inFlight;
  DateTime? _lastSyncedAt;

  static const _minInterval = Duration(seconds: 30);

  Future<UserLocationSyncResult?> sync({bool force = false}) async {
    if (_inFlight != null) return _inFlight;

    if (!force &&
        _lastSyncedAt != null &&
        DateTime.now().difference(_lastSyncedAt!) < _minInterval) {
      return null;
    }

    final future = _run();
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  /// Persists coordinates already obtained (e.g. from [MapScreen]).
  Future<UserLocationSyncResult?> syncCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    if (_inFlight != null) return _inFlight;

    final future = _persistCoordinates(latitude, longitude);
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<UserLocationSyncResult?> _run() async {
    final result =
        await _ref.read(userLocationServiceProvider).syncCurrentLocation();
    return _applyResult(result);
  }

  Future<UserLocationSyncResult?> _persistCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      if (Env.useMockApi) {
        final storage = _ref.read(profileStorageProvider);
        final current = await storage.read();
        if (current == null) {
          return const UserLocationSyncResult(
            status: UserLocationSyncStatus.unavailable,
          );
        }
        final updated = current.copyWith(
          latitude: latitude,
          longitude: longitude,
        );
        await storage.write(updated);
        return _applyResult(
          UserLocationSyncResult(
            status: UserLocationSyncStatus.synced,
            profile: updated,
          ),
        );
      }

      final profile = await _ref.read(authRepositoryProvider).updateLocation(
            latitude: latitude,
            longitude: longitude,
          );
      return _applyResult(
        UserLocationSyncResult(
          status: UserLocationSyncStatus.synced,
          profile: profile,
        ),
      );
    } catch (_) {
      return const UserLocationSyncResult(
        status: UserLocationSyncStatus.unavailable,
      );
    }
  }

  UserLocationSyncResult? _applyResult(UserLocationSyncResult result) {
    if (result.isSuccess) {
      _lastSyncedAt = DateTime.now();
      if (result.profile != null) {
        _ref.read(authStateProvider.notifier).applyProfileFromLocation(
              result.profile!,
            );
      }
    }
    return result;
  }
}
