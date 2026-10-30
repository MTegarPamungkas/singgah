import 'package:singgah/domain/services/biometric_service.dart';
import 'package:singgah/domain/services/geofencing_service.dart';
import 'package:singgah/domain/services/location_service.dart';
import 'package:singgah/domain/services/notification_service.dart';

class CheckLocationPermission {
  const CheckLocationPermission(this._service);
  final LocationService _service;

  Future<LocationPermissionState> call() => _service.checkPermission();
}

class RequestForegroundLocation {
  const RequestForegroundLocation(this._service);
  final LocationService _service;

  Future<LocationPermissionState> call() => _service.requestForeground();
}

class RequestBackgroundLocation {
  const RequestBackgroundLocation(this._service);
  final LocationService _service;

  Future<LocationPermissionState> call() => _service.requestBackground();
}

class OpenAppSettings {
  const OpenAppSettings(this._service);
  final LocationService _service;

  Future<void> call() => _service.openAppSettings();
}

class OpenLocationSettings {
  const OpenLocationSettings(this._service);
  final LocationService _service;

  Future<void> call() => _service.openLocationSettings();
}

class GetCurrentLocation {
  const GetCurrentLocation(this._service);
  final LocationService _service;

  Future<DeviceLocation?> call() => _service.currentLocation();
}

class IsLocationServiceEnabled {
  const IsLocationServiceEnabled(this._service);
  final LocationService _service;

  Future<bool> call() => _service.isServiceEnabled();
}

class GeofencingSupported {
  const GeofencingSupported(this._service);
  final GeofencingService _service;

  bool call() => _service.isSupported;
}

class RequestNotificationPermission {
  const RequestNotificationPermission(this._service);
  final NotificationService _service;

  Future<bool> call() => _service.requestPermission();
}

class CheckBiometrics {
  const CheckBiometrics(this._service);
  final BiometricService _service;

  Future<bool> call() => _service.isAvailable();
}

class UnlockWithBiometrics {
  const UnlockWithBiometrics(this._service);
  final BiometricService _service;

  Future<bool> call({required String reason}) =>
      _service.authenticate(reason: reason);
}
