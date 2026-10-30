import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:singgah/domain/services/geofencing_service.dart';
import 'package:singgah/domain/usecases/geofence_planner.dart';

GeofencingService createGeofencingService() => GeofencingServiceIO();

class GeofencingServiceIO implements GeofencingService {
  static const MethodChannel _channel = MethodChannel('dev.singgah/geofencing');

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<GeofenceRegistrationResult> syncGeofences(
    List<GeofenceRequest> requests,
  ) async {
    if (!isSupported) {
      return GeofenceRegistrationResult(
        registered: const [],
        failed: requests.map((request) => request.id).toList(growable: false),
      );
    }
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'syncGeofences',
        {
          'geofences': requests
              .map((request) => request.toNativeJson())
              .toList(),
        },
      );
      final registered =
          (response?['registered'] as List?)
              ?.map((item) => item.toString())
              .toList(growable: false) ??
          const <String>[];
      final failed =
          (response?['failed'] as List?)
              ?.map((item) => item.toString())
              .toList(growable: false) ??
          const <String>[];
      return GeofenceRegistrationResult(registered: registered, failed: failed);
    } on MissingPluginException {
      return GeofenceRegistrationResult(
        registered: const [],
        failed: requests.map((request) => request.id).toList(growable: false),
      );
    } on PlatformException {
      return GeofenceRegistrationResult(
        registered: const [],
        failed: requests.map((request) => request.id).toList(growable: false),
      );
    }
  }

  @override
  Future<void> clearAll() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('clearGeofences');
    } on MissingPluginException {
      // Tests and unsupported devices simply have nothing to clear.
    } on PlatformException {
      // Clearing is best effort; stale geofences are replaced on next sync.
    }
  }

  @override
  Future<List<NativeGeofenceTransition>> drainTransitions() async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeListMethod<dynamic>('drainTransitions');
      if (raw == null) return const [];
      return raw
          .whereType<Map>()
          .map(
            (row) => NativeGeofenceTransition.fromMap(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList(growable: false);
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }
}
