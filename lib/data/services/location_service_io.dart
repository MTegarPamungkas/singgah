import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:singgah/domain/entities/geo_point.dart';
import 'package:singgah/domain/services/location_service.dart';

LocationService createLocationService() => LocationServiceIO();

class LocationServiceIO implements LocationService {
  @override
  bool get isSupported => !kIsWeb;

  @override
  Future<bool> isServiceEnabled() async {
    try {
      return await geo.Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<LocationPermissionState> checkPermission() async {
    try {
      final enabled = await isServiceEnabled();
      if (!enabled) return LocationPermissionState.serviceDisabled;
      final permission = await geo.Geolocator.checkPermission();
      return _map(permission);
    } catch (_) {
      return LocationPermissionState.denied;
    }
  }

  @override
  Future<LocationPermissionState> requestForeground() async {
    try {
      final enabled = await isServiceEnabled();
      if (!enabled) return LocationPermissionState.serviceDisabled;
      final permission = await geo.Geolocator.requestPermission();
      return _map(permission);
    } catch (_) {
      return LocationPermissionState.denied;
    }
  }

  @override
  Future<LocationPermissionState> requestBackground() async {
    final current = await checkPermission();
    if (current == LocationPermissionState.grantedBackground) return current;
    if (current != LocationPermissionState.grantedForeground &&
        current != LocationPermissionState.grantedBackground) {
      return current;
    }
    try {
      final status = await ph.Permission.locationAlways.request();
      if (status.isGranted || status.isLimited) {
        return LocationPermissionState.grantedBackground;
      }
      // On Android 11+ the OS no longer shows an in-app dialog for background
      // location. Send the user to settings, where "Allow all the time" is.
      if (status.isPermanentlyDenied || status.isDenied) {
        await ph.openAppSettings();
      }
      return await checkPermission();
    } catch (_) {
      return current;
    }
  }

  @override
  Future<void> openAppSettings() => ph.openAppSettings();

  @override
  Future<void> openLocationSettings() => geo.Geolocator.openLocationSettings();

  @override
  Future<DeviceLocation?> currentLocation() async {
    try {
      final permission = await checkPermission();
      if (permission != LocationPermissionState.grantedForeground &&
          permission != LocationPermissionState.grantedBackground) {
        return null;
      }
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return DeviceLocation(
        point: GeoPoint(position.latitude, position.longitude),
        accuracyMeters: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (_) {
      return null;
    }
  }

  LocationPermissionState _map(geo.LocationPermission permission) {
    return switch (permission) {
      geo.LocationPermission.always =>
        LocationPermissionState.grantedBackground,
      geo.LocationPermission.whileInUse =>
        LocationPermissionState.grantedForeground,
      geo.LocationPermission.deniedForever =>
        LocationPermissionState.permanentlyDenied,
      geo.LocationPermission.denied ||
      geo.LocationPermission.unableToDetermine =>
        LocationPermissionState.denied,
    };
  }
}
