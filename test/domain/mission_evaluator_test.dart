import 'package:flutter_test/flutter_test.dart';

import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/usecases/mission_evaluator.dart';

SinggahMission mission({
  String id = 'm1',
  String placeId = 'p1',
  bool active = true,
  DateTime? deletedAt,
  Set<int> repeatDays = const {},
  int start = 0,
  int end = 24 * 60 - 1,
  MissionTrigger trigger = MissionTrigger.arrive,
  DateTime? lastTriggeredAt,
}) {
  return SinggahMission(
    id: id,
    ownerId: 'owner',
    placeId: placeId,
    title: 'Kirim laporan',
    trigger: trigger,
    repeatDays: repeatDays,
    windowStartMinutes: start,
    windowEndMinutes: end,
    isActive: active,
    deletedAt: deletedAt,
    lastTriggeredAt: lastTriggeredAt,
  );
}

void main() {
  const evaluator = MissionEvaluator();
  final mondayMorning = DateTime(2026, 10, 26, 10);

  test('fires an active mission inside its day and window', () {
    final result = evaluator.evaluate(
      mission: mission(repeatDays: const {1}, start: 8 * 60, end: 11 * 60),
      transition: MissionTrigger.arrive,
      now: mondayMorning,
    );
    expect(result.triggered, isTrue);
    expect(result.reason, MissionDecisionReason.triggered);
  });

  test('supports overnight windows', () {
    final result = evaluator.evaluate(
      mission: mission(start: 22 * 60, end: 2 * 60),
      transition: MissionTrigger.arrive,
      now: DateTime(2026, 10, 26, 23, 30),
    );
    expect(result.triggered, isTrue);
  });

  test('rejects inactive, deleted, wrong-day, out-of-window missions', () {
    expect(
      evaluator
          .evaluate(
            mission: mission(active: false),
            transition: MissionTrigger.arrive,
            now: mondayMorning,
          )
          .reason,
      MissionDecisionReason.inactive,
    );
    expect(
      evaluator
          .evaluate(
            mission: mission(deletedAt: mondayMorning),
            transition: MissionTrigger.arrive,
            now: mondayMorning,
          )
          .reason,
      MissionDecisionReason.deleted,
    );
    expect(
      evaluator
          .evaluate(
            mission: mission(repeatDays: const {2}),
            transition: MissionTrigger.arrive,
            now: mondayMorning,
          )
          .reason,
      MissionDecisionReason.wrongDay,
    );
    expect(
      evaluator
          .evaluate(
            mission: mission(start: 18 * 60, end: 20 * 60),
            transition: MissionTrigger.arrive,
            now: mondayMorning,
          )
          .reason,
      MissionDecisionReason.outsideWindow,
    );
  });

  test('rejects a transition that does not match the mission', () {
    final result = evaluator.evaluate(
      mission: mission(trigger: MissionTrigger.leave),
      transition: MissionTrigger.arrive,
      now: mondayMorning,
    );
    expect(result.reason, MissionDecisionReason.transitionMismatch);
  });

  test('cooldown absorbs duplicate OS callbacks', () {
    final result = evaluator.evaluate(
      mission: mission(),
      transition: MissionTrigger.arrive,
      now: mondayMorning,
      lastTriggeredAt: mondayMorning.subtract(const Duration(minutes: 2)),
    );
    expect(result.reason, MissionDecisionReason.cooldown);

    final later = evaluator.evaluate(
      mission: mission(),
      transition: MissionTrigger.arrive,
      now: mondayMorning,
      lastTriggeredAt: mondayMorning.subtract(const Duration(minutes: 6)),
    );
    expect(later.triggered, isTrue);
  });

  test('triggeredForPlace filters by place and last trigger map', () {
    final missions = [
      mission(id: 'a', placeId: 'p1'),
      mission(id: 'b', placeId: 'p2'),
      mission(
        id: 'c',
        placeId: 'p1',
        lastTriggeredAt: mondayMorning.subtract(const Duration(minutes: 1)),
      ),
    ];
    final result = evaluator.triggeredForPlace(
      missions: missions,
      placeId: 'p1',
      transition: MissionTrigger.arrive,
      now: mondayMorning,
    );
    expect(result.map((item) => item.id), ['a']);
  });
}
