import 'package:equatable/equatable.dart';

import 'singgah_mission.dart';

enum SinggahEventSource { geofence, manual }

class SinggahEvent extends Equatable {
  const SinggahEvent({
    required this.id,
    required this.ownerId,
    required this.placeName,
    required this.trigger,
    required this.occurredAt,
    this.placeId,
    this.missionId,
    this.titipanId,
    this.source = SinggahEventSource.geofence,
    this.acknowledged = false,
  });

  final String id;
  final String ownerId;
  final String? placeId;
  final String placeName;
  final String? missionId;
  final String? titipanId;
  final MissionTrigger trigger;
  final DateTime occurredAt;
  final SinggahEventSource source;
  final bool acknowledged;

  String get dedupeKey =>
      '${placeId ?? placeName}:${trigger.name}:${occurredAt.toUtc().millisecondsSinceEpoch ~/ 60000}';

  SinggahEvent copyWith({bool? acknowledged}) => SinggahEvent(
    id: id,
    ownerId: ownerId,
    placeId: placeId,
    placeName: placeName,
    missionId: missionId,
    titipanId: titipanId,
    trigger: trigger,
    occurredAt: occurredAt,
    source: source,
    acknowledged: acknowledged ?? this.acknowledged,
  );

  @override
  List<Object?> get props => [
    id,
    ownerId,
    placeId,
    placeName,
    missionId,
    titipanId,
    trigger,
    occurredAt,
    source,
    acknowledged,
  ];
}
