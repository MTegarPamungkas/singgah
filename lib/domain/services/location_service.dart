import 'package:singgah/domain/entities/geo_point.dart';

enum LocationPermissionState {
  grantedForeground,
  grantedBackground,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class DeviceLocation {
  const DeviceLocation({
    required this.point,
    required this.accuracyMeters,
    required this.timestamp,
  });

  final GeoPoint point;
  final double accuracyMeters;
  final DateTime timestamp;

  bool get isAccurate => accuracyMeters <= 100;
}

abstract interface class LocationService {
  bool get isSupported;

  Future<bool> isServiceEnabled();

  Future<LocationPermissionState> checkPermission();

  Future<LocationPermissionState> requestForeground();

  /// Opens the OS settings page when Android requires "Allow all the time" to
  /// be granted manually. Returns the resulting state.
  Future<LocationPermissionState> requestBackground();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();

  Future<DeviceLocation?> currentLocation();
}
