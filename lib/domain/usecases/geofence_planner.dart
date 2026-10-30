import 'package:equatable/equatable.dart';

import 'package:singgah/domain/entities/geo_point.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/entities/titipan.dart';

enum GeofenceKind { mission, titipan }

class GeofenceRequest extends Equatable {
  const GeofenceRequest({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.transition,
    this.placeId,
    this.placeName = '',
    this.missionId,
    this.titipanId,
    this.repeatDays = const {},
    this.windowStartMinutes = 0,
    this.windowEndMinutes = 24 * 60 - 1,
  });

  /// Stable native id, at most 100 characters.
  final String id;
  final GeofenceKind kind;
  final String title;
  final String body;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final MissionTrigger transition;
  final String? placeId;
  final String placeName;
  final String? missionId;
  final String? titipanId;
  final Set<int> repeatDays;
  final int windowStartMinutes;
  final int windowEndMinutes;

  GeoPoint get point => GeoPoint(latitude, longitude);

  Map<String, dynamic> toNativeJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'body': body,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radiusMeters,
    'transition': transition.name,
    'place_id': placeId,
    'place_name': placeName,
    'mission_id': missionId,
    'titipan_id': titipanId,
    'repeat_days': (repeatDays.toList()..sort()),
    'window_start_minutes': windowStartMinutes,
    'window_end_minutes': windowEndMinutes,
  };

  @override
  List<Object?> get props => [
    id,
    kind,
    title,
    body,
    latitude,
    longitude,
    radiusMeters,
    transition,
    placeId,
    placeName,
    missionId,
    titipanId,
    repeatDays,
    windowStartMinutes,
    windowEndMinutes,
  ];
}

class GeofencePlan extends Equatable {
  const GeofencePlan({
    required this.requests,
    required this.skipped,
    required this.generatedAt,
    this.center,
    this.enabled = true,
  });

  const GeofencePlan.disabled(DateTime now)
    : requests = const [],
      skipped = const [],
      generatedAt = now,
      center = null,
      enabled = false;

  final List<GeofenceRequest> requests;
  final List<String> skipped;
  final DateTime generatedAt;
  final GeoPoint? center;
  final bool enabled;

  int get count => requests.length;

  bool get isEmpty => requests.isEmpty;

  @override
  List<Object?> get props => [requests, skipped, generatedAt, center, enabled];
}

/// Chooses which geofences to register for the Android OS.
///
/// Android caps an app at about 100 geofences. Registering everything would
/// silently drop the ones the user needs. Instead we score each candidate by
/// relevance today and proximity, cap the list, and re-plan when the user
/// moves far enough or data changes.
class GeofencePlanner {
  const GeofencePlanner({this.refreshDistanceMeters = 2000});

  final double refreshDistanceMeters;

  GeofencePlan plan({
    required List<SinggahMission> missions,
    required Map<String, Titik> places,
    required List<Titipan> titipans,
    required Set<String> acceptedTitipanIds,
    required DateTime now,
    GeoPoint? current,
    int maxCount = 90,
    bool enabled = true,
  }) {
    if (!enabled) return GeofencePlan.disabled(now);

    final candidates = <_Candidate>[];

    for (final mission in missions) {
      if (mission.isDeleted || !mission.isActive) continue;
      final place = places[mission.placeId];
      if (place == null || place.isDeleted || !place.hasValidCoordinates) {
        continue;
      }
      final score = mission.isScheduled(now)
          ? 0
          : mission.runsOn(now.weekday)
          ? 1
          : 2;
      final distance = current?.distanceTo(
        GeoPoint(place.latitude, place.longitude),
      );
      candidates.add(
        _Candidate(
          request: GeofenceRequest(
            id: 'mission:${mission.id}',
            kind: GeofenceKind.mission,
            title: 'Singgah · ${place.name}',
            body: mission.title,
            latitude: place.latitude,
            longitude: place.longitude,
            radiusMeters: place.radiusMeters.clamp(100, 2000),
            transition: mission.trigger,
            placeId: place.id,
            placeName: place.name,
            missionId: mission.id,
            repeatDays: mission.repeatDays,
            windowStartMinutes: mission.windowStartMinutes,
            windowEndMinutes: mission.windowEndMinutes,
          ),
          score: score,
          distance: distance,
          updatedAt: mission.updatedAt ?? mission.createdAt,
        ),
      );
    }

    for (final titipan in titipans) {
      if (!acceptedTitipanIds.contains(titipan.id)) continue;
      if (titipan.isDeleted || !titipan.hasValidCoordinates) continue;
      final distance = current?.distanceTo(
        GeoPoint(titipan.latitude, titipan.longitude),
      );
      candidates.add(
        _Candidate(
          request: GeofenceRequest(
            id: 'titipan:${titipan.id}',
            kind: GeofenceKind.titipan,
            title: 'Titipan · ${titipan.placeName}',
            body: titipan.title,
            latitude: titipan.latitude,
            longitude: titipan.longitude,
            radiusMeters: titipan.radiusMeters.clamp(100, 2000),
            transition: titipan.trigger,
            placeId: titipan.placeId,
            placeName: titipan.placeName,
            titipanId: titipan.id,
          ),
          score: 0,
          distance: distance,
          updatedAt: titipan.updatedAt ?? titipan.createdAt,
        ),
      );
    }

    candidates.sort((a, b) {
      final byScore = a.score.compareTo(b.score);
      if (byScore != 0) return byScore;
      if (a.distance != null && b.distance != null) {
        final byDistance = a.distance!.compareTo(b.distance!);
        if (byDistance != 0) return byDistance;
      } else if (a.distance != null) {
        return -1;
      } else if (b.distance != null) {
        return 1;
      }
      final byUpdated = (b.updatedAt ?? DateTime(0)).compareTo(
        a.updatedAt ?? DateTime(0),
      );
      if (byUpdated != 0) return byUpdated;
      return a.request.id.compareTo(b.request.id);
    });

    final safeMax = maxCount < 1 ? 1 : maxCount;
    final selected = candidates.take(safeMax).toList(growable: false);
    final skipped = candidates
        .skip(safeMax)
        .map((candidate) => candidate.request.id)
        .toList(growable: false);

    return GeofencePlan(
      requests: selected
          .map((candidate) => candidate.request)
          .toList(growable: false),
      skipped: skipped,
      generatedAt: now,
      center: current,
      enabled: true,
    );
  }

  /// Re-plan when the user has moved far enough for distance ordering to
  /// change, or when there is no previous centre to compare with.
  bool shouldRefresh({GeoPoint? previous, GeoPoint? current}) {
    if (current == null) return false;
    if (previous == null) return true;
    return previous.distanceTo(current) >= refreshDistanceMeters;
  }
}

class _Candidate {
  const _Candidate({
    required this.request,
    required this.score,
    required this.distance,
    required this.updatedAt,
  });

  final GeofenceRequest request;
  final int score;
  final double? distance;
  final DateTime? updatedAt;
}
