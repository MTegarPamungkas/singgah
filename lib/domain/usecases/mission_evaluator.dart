import 'package:equatable/equatable.dart';

import 'package:singgah/domain/entities/singgah_mission.dart';

enum MissionDecisionReason {
  triggered,
  inactive,
  deleted,
  wrongDay,
  outsideWindow,
  transitionMismatch,
  cooldown,
}

class MissionDecision extends Equatable {
  const MissionDecision(this.reason, {this.triggered = false});

  const MissionDecision.triggered()
    : this(MissionDecisionReason.triggered, triggered: true);

  final MissionDecisionReason reason;
  final bool triggered;

  @override
  List<Object?> get props => [reason, triggered];
}

/// Pure evaluation of a single geofence transition.
///
/// Android reports ENTER/EXIT; this layer decides whether that transition is
/// meaningful for a Mission, applying the weekday, time window, active flag,
/// and a short cooldown to absorb duplicated OS callbacks.
class MissionEvaluator {
  const MissionEvaluator({this.cooldown = const Duration(minutes: 5)});

  final Duration cooldown;

  MissionDecision evaluate({
    required SinggahMission mission,
    required MissionTrigger transition,
    required DateTime now,
    DateTime? lastTriggeredAt,
  }) {
    if (mission.isDeleted) {
      return const MissionDecision(MissionDecisionReason.deleted);
    }
    if (!mission.isActive) {
      return const MissionDecision(MissionDecisionReason.inactive);
    }
    if (!mission.runsOn(now.weekday)) {
      return const MissionDecision(MissionDecisionReason.wrongDay);
    }
    if (!mission.isInsideWindow(now)) {
      return const MissionDecision(MissionDecisionReason.outsideWindow);
    }
    if (mission.trigger != transition) {
      return const MissionDecision(MissionDecisionReason.transitionMismatch);
    }
    final last = lastTriggeredAt ?? mission.lastTriggeredAt;
    if (last != null && now.difference(last).abs() < cooldown) {
      return const MissionDecision(MissionDecisionReason.cooldown);
    }
    return const MissionDecision.triggered();
  }

  /// Evaluates every Mission attached to a Place and returns those that should
  /// notify. A single transition can match multiple Missions.
  List<SinggahMission> triggeredForPlace({
    required Iterable<SinggahMission> missions,
    required String placeId,
    required MissionTrigger transition,
    required DateTime now,
    Map<String, DateTime> lastTriggered = const {},
  }) {
    final result = <SinggahMission>[];
    for (final mission in missions) {
      if (mission.placeId != placeId) continue;
      final decision = evaluate(
        mission: mission,
        transition: transition,
        now: now,
        lastTriggeredAt: lastTriggered[mission.id],
      );
      if (decision.triggered) result.add(mission);
    }
    return result;
  }
}
