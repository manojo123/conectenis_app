import 'package:geolocator/geolocator.dart';

enum LocationAccessStatus {
  unknown,
  serviceDisabled,
  denied,
  deniedForever,
  granted,
}

class LocationPermissionService {
  Future<LocationAccessStatus> checkStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationAccessStatus.serviceDisabled;

    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  Future<LocationAccessStatus> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationAccessStatus.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return _mapPermission(permission);
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  LocationAccessStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccessStatus.granted;
      case LocationPermission.deniedForever:
        return LocationAccessStatus.deniedForever;
      case LocationPermission.denied:
        return LocationAccessStatus.denied;
      case LocationPermission.unableToDetermine:
        return LocationAccessStatus.unknown;
    }
  }
}
