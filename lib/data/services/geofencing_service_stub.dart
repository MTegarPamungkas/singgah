import 'package:singgah/domain/services/geofencing_service.dart';
import 'package:singgah/domain/usecases/geofence_planner.dart';

GeofencingService createGeofencingService() => GeofencingServiceStub();

class GeofencingServiceStub implements GeofencingService {
  @override
  bool get isSupported => false;

  @override
  Future<GeofenceRegistrationResult> syncGeofences(
    List<GeofenceRequest> requests,
  ) async => GeofenceRegistrationResult(
    registered: const [],
    failed: requests.map((request) => request.id).toList(growable: false),
  );

  @override
  Future<void> clearAll() async {}

  @override
  Future<List<NativeGeofenceTransition>> drainTransitions() async => const [];
}
