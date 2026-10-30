import 'package:equatable/equatable.dart';

import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/usecases/geofence_planner.dart';

class NativeGeofenceTransition extends Equatable {
  const NativeGeofenceTransition({
    required this.requestId,
    required this.kind,
    required this.transition,
    required this.occurredAt,
    required this.title,
    required this.body,
    this.placeId,
    this.placeName,
    this.missionId,
    this.titipanId,
  });

  final String requestId;
  final GeofenceKind kind;
  final MissionTrigger transition;
  final DateTime occurredAt;
  final String title;
  final String body;
  final String? placeId;
  final String? placeName;
  final String? missionId;
  final String? titipanId;

  factory NativeGeofenceTransition.fromMap(Map<String, dynamic> map) {
    final trigger = map['transition']?.toString() == 'leave'
        ? MissionTrigger.leave
        : MissionTrigger.arrive;
    final kind = map['kind']?.toString() == 'titipan'
        ? GeofenceKind.titipan
        : GeofenceKind.mission;
    return NativeGeofenceTransition(
      requestId: map['request_id']?.toString() ?? '',
      kind: kind,
      transition: trigger,
      occurredAt:
          DateTime.tryParse(map['occurred_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      title: map['title']?.toString() ?? 'Singgah',
      body: map['body']?.toString() ?? '',
      placeId: map['place_id']?.toString(),
      placeName: map['place_name']?.toString(),
      missionId: map['mission_id']?.toString(),
      titipanId: map['titipan_id']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    requestId,
    kind,
    transition,
    occurredAt,
    title,
    body,
    placeId,
    placeName,
    missionId,
    titipanId,
  ];
}

class GeofenceRegistrationResult {
  const GeofenceRegistrationResult({
    required this.registered,
    required this.failed,
  });

  final List<String> registered;
  final List<String> failed;

  bool get success => failed.isEmpty;
}

abstract interface class GeofencingService {
  bool get isSupported;

  Future<GeofenceRegistrationResult> syncGeofences(
    List<GeofenceRequest> requests,
  );

  Future<void> clearAll();

  /// Returns transitions captured while the app was closed and clears the
  /// native queue. Safe to call repeatedly.
  Future<List<NativeGeofenceTransition>> drainTransitions();
}
