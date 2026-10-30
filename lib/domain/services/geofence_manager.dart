import 'package:singgah/domain/entities/geofence_summary.dart';

/// Application-facing view of OS geofence registration.
///
/// The native channel, planner, and local cache all sit behind this seam so
/// blocs and tests never touch platform channels directly.
abstract interface class GeofenceManager {
  Stream<GeofenceSummary> get summaries;

  Future<GeofenceSummary> summary();

  Future<void> start();

  Future<void> refresh({bool force = false});

  Future<int> syncTransitions();
}
