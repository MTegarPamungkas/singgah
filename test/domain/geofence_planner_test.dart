import 'package:flutter_test/flutter_test.dart';

import 'package:singgah/domain/entities/geo_point.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/usecases/geofence_planner.dart';

final now = DateTime(2026, 10, 26, 9); // Monday, 09:00

Titik place(String id, double lat, double lon) => Titik(
  id: id,
  ownerId: 'owner',
  name: 'Place $id',
  latitude: lat,
  longitude: lon,
  radiusMeters: 150,
);

SinggahMission mission(
  String id,
  String placeId, {
  bool active = true,
  DateTime? deletedAt,
  Set<int> days = const {},
  int start = 0,
  int end = 24 * 60 - 1,
}) => SinggahMission(
  id: id,
  ownerId: 'owner',
  placeId: placeId,
  title: 'Mission $id',
  repeatDays: days,
  windowStartMinutes: start,
  windowEndMinutes: end,
  isActive: active,
  deletedAt: deletedAt,
);

Titipan note(String id, {bool deleted = false}) => Titipan(
  id: id,
  senderId: 'friend',
  senderName: 'Rani',
  placeName: 'Alfamart',
  latitude: -6.26,
  longitude: 106.81,
  title: 'Ambil paket',
  body: 'Di kasir',
  deletedAt: deleted ? now : null,
);

void main() {
  const planner = GeofencePlanner();

  test('registers active missions and skips paused/deleted ones', () {
    final plan = planner.plan(
      missions: [
        mission('active', 'p1'),
        mission('paused', 'p1', active: false),
        mission('deleted', 'p1', deletedAt: now),
        mission('missing-place', 'p9'),
      ],
      places: {'p1': place('p1', -6.2, 106.8)},
      titipans: const [],
      acceptedTitipanIds: const {},
      now: now,
    );
    expect(plan.requests.map((request) => request.missionId), ['active']);
    expect(plan.count, 1);
  });

  test('caps the plan and records skipped ids', () {
    final places = {
      for (var i = 0; i < 5; i++) 'p$i': place('p$i', -6.2 + i * 0.01, 106.8),
    };
    final missions = [for (var i = 0; i < 5; i++) mission('m$i', 'p$i')];
    final plan = planner.plan(
      missions: missions,
      places: places,
      titipans: const [],
      acceptedTitipanIds: const {},
      now: now,
      maxCount: 2,
      current: const GeoPoint(-6.2, 106.8),
    );
    expect(plan.count, 2);
    expect(plan.skipped.length, 3);
    // Closest place wins when scores tie.
    expect(plan.requests.first.missionId, 'm0');
  });

  test('scheduled missions rank above outside-window missions', () {
    final plan = planner.plan(
      missions: [
        mission('later', 'far', start: 18 * 60, end: 20 * 60),
        mission('now', 'near', start: 8 * 60, end: 11 * 60),
      ],
      places: {
        'far': place('far', -6.1, 106.7),
        'near': place('near', -6.9, 106.9),
      },
      titipans: const [],
      acceptedTitipanIds: const {},
      now: now,
      maxCount: 1,
      current: const GeoPoint(-6.1, 106.7),
    );
    expect(plan.requests.single.missionId, 'now');
  });

  test('only accepted, live Titipan become geofences', () {
    final plan = planner.plan(
      missions: const [],
      places: const {},
      titipans: [
        note('accepted'),
        note('pending'),
        note('deleted', deleted: true),
      ],
      acceptedTitipanIds: const {'accepted', 'deleted'},
      now: now,
    );
    expect(plan.requests.map((request) => request.titipanId), ['accepted']);
    expect(plan.requests.single.kind, GeofenceKind.titipan);
  });

  test('disabling reminders produces an empty plan', () {
    final plan = planner.plan(
      missions: [mission('m', 'p')],
      places: {'p': place('p', -6.2, 106.8)},
      titipans: const [],
      acceptedTitipanIds: const {},
      now: now,
      enabled: false,
    );
    expect(plan.enabled, isFalse);
    expect(plan.isEmpty, isTrue);
  });

  test('skips places with invalid coordinates and clamps radius', () {
    final plan = planner.plan(
      missions: [mission('m1', 'bad'), mission('m2', 'tiny')],
      places: {
        'bad': const Titik(
          id: 'bad',
          ownerId: 'owner',
          name: 'Broken',
          latitude: 500,
          longitude: 106.8,
        ),
        'tiny': const Titik(
          id: 'tiny',
          ownerId: 'owner',
          name: 'Tiny',
          latitude: -6.2,
          longitude: 106.8,
          radiusMeters: 20,
        ),
      },
      titipans: const [],
      acceptedTitipanIds: const {},
      now: now,
    );
    expect(plan.requests.single.missionId, 'm2');
    expect(plan.requests.single.radiusMeters, 100);
  });

  test('handles null distances and deterministic ties', () {
    final plan = planner.plan(
      missions: [mission('b', 'pb'), mission('a', 'pa')],
      places: {'pa': place('pa', -6.2, 106.8), 'pb': place('pb', -6.3, 106.9)},
      titipans: const [],
      acceptedTitipanIds: const {},
      now: now,
      maxCount: 0,
    );
    // maxCount is clamped to one item; identical scores break ties by id.
    expect(plan.count, 1);
    expect(plan.requests.single.missionId, 'a');
  });

  test('orders by updated time when no current location exists', () {
    final older = mission(
      'older',
      'p',
    ).copyWith(updatedAt: DateTime(2026, 10, 1));
    final newer = mission(
      'newer',
      'p',
    ).copyWith(updatedAt: DateTime(2026, 10, 20));
    final plan = planner.plan(
      missions: [older, newer],
      places: {'p': place('p', -6.2, 106.8)},
      titipans: const [],
      acceptedTitipanIds: const {},
      now: now,
    );
    expect(plan.requests.first.missionId, 'newer');
  });

  test('distance ordering uses the current location when available', () {
    final plan = planner.plan(
      missions: [mission('far', 'far'), mission('near', 'near')],
      places: {
        'far': place('far', -6.5, 107.1),
        'near': place('near', -6.2001, 106.8001),
      },
      titipans: [
        Titipan(
          id: 't1',
          senderId: 'friend',
          senderName: 'Rani',
          placeName: 'Warung',
          latitude: -6.2002,
          longitude: 106.8002,
          title: 'Ambil pesan',
          body: 'Kasir',
        ),
      ],
      acceptedTitipanIds: const {'t1'},
      now: now,
      current: const GeoPoint(-6.2, 106.8),
    );
    expect(plan.requests.first.missionId, 'near');
    expect(plan.center, const GeoPoint(-6.2, 106.8));
    expect(plan.requests.map((request) => request.titipanId), contains('t1'));
  });

  test('invalid and deleted Titipan are dropped', () {
    final invalid = Titipan(
      id: 'bad',
      senderId: 'friend',
      senderName: 'Rani',
      placeName: 'Nowhere',
      latitude: 100,
      longitude: 200,
      title: 'Bad',
      body: 'Bad',
    );
    final plan = planner.plan(
      missions: const [],
      places: const {},
      titipans: [invalid, note('deleted', deleted: true)],
      acceptedTitipanIds: const {'bad', 'deleted'},
      now: now,
    );
    expect(plan.requests, isEmpty);
  });

  test('request and plan value equality cover all reviewed fields', () {
    final request = GeofenceRequest(
      id: 'm1',
      kind: GeofenceKind.mission,
      title: 'Singgah · Rumah',
      body: 'Bawa charger',
      latitude: -6.2,
      longitude: 106.8,
      radiusMeters: 150,
      transition: MissionTrigger.leave,
      placeId: 'p1',
      placeName: 'Rumah',
      missionId: 'm1',
      repeatDays: const {1, 2},
      windowStartMinutes: 60,
      windowEndMinutes: 120,
    );
    final copy = GeofenceRequest(
      id: 'm1',
      kind: GeofenceKind.mission,
      title: 'Singgah · Rumah',
      body: 'Bawa charger',
      latitude: -6.2,
      longitude: 106.8,
      radiusMeters: 150,
      transition: MissionTrigger.leave,
      placeId: 'p1',
      placeName: 'Rumah',
      missionId: 'm1',
      repeatDays: const {1, 2},
      windowStartMinutes: 60,
      windowEndMinutes: 120,
    );
    expect(request, copy);
    expect(request.point, const GeoPoint(-6.2, 106.8));
    expect(request.toNativeJson()['radius'], 150);

    final plan = GeofencePlan(
      requests: [request],
      skipped: const ['x'],
      generatedAt: now,
      center: const GeoPoint(-6.2, 106.8),
    );
    final samePlan = GeofencePlan(
      requests: [copy],
      skipped: const ['x'],
      generatedAt: now,
      center: const GeoPoint(-6.2, 106.8),
    );
    expect(plan, samePlan);
    expect(plan.isEmpty, isFalse);
    expect(GeofencePlan.disabled(now).isEmpty, isTrue);
  });

  test('refresh policy reacts to meaningful movement only', () {
    const here = GeoPoint(-6.2, 106.8);
    expect(planner.shouldRefresh(previous: null, current: null), isFalse);
    expect(planner.shouldRefresh(previous: null, current: here), isTrue);
    expect(
      planner.shouldRefresh(
        previous: here,
        current: const GeoPoint(-6.2001, 106.8001),
      ),
      isFalse,
    );
    expect(
      planner.shouldRefresh(
        previous: here,
        current: const GeoPoint(-6.25, 106.85),
      ),
      isTrue,
    );
  });
}
