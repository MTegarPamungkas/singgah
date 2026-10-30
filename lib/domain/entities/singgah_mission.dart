import 'package:equatable/equatable.dart';

import 'package:singgah/core/utils/date_time_x.dart';

enum MissionTrigger { arrive, leave }

class SinggahMission extends Equatable {
  const SinggahMission({
    required this.id,
    required this.ownerId,
    required this.placeId,
    required this.title,
    this.note = '',
    this.trigger = MissionTrigger.arrive,
    this.repeatDays = const {},
    this.windowStartMinutes = 0,
    this.windowEndMinutes = 24 * 60 - 1,
    this.isActive = true,
    this.lastTriggeredAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String ownerId;
  final String placeId;
  final String title;
  final String note;
  final MissionTrigger trigger;

  /// Empty means every day. Values are 1 (Monday) through 7 (Sunday).
  final Set<int> repeatDays;
  final int windowStartMinutes;
  final int windowEndMinutes;
  final bool isActive;
  final DateTime? lastTriggeredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get repeatsEveryDay => repeatDays.isEmpty || repeatDays.length == 7;

  bool runsOn(int weekday) => repeatsEveryDay || repeatDays.contains(weekday);

  bool isInsideWindow(DateTime now) {
    return minutesInWindow(
      now.hour * 60 + now.minute,
      start: windowStartMinutes,
      end: windowEndMinutes,
    );
  }

  /// A Mission is "scheduled" when it is active, runs today, and sits inside
  /// its time window. Geofence registration still happens outside the window
  /// because the user may arrive early; this only drives UI hints.
  bool isScheduled(DateTime now) =>
      isActive && !isDeleted && runsOn(now.weekday) && isInsideWindow(now);

  bool get hasFreeWindow => windowStartMinutes == windowEndMinutes;

  SinggahMission copyWith({
    String? placeId,
    String? title,
    String? note,
    MissionTrigger? trigger,
    Set<int>? repeatDays,
    int? windowStartMinutes,
    int? windowEndMinutes,
    bool? isActive,
    DateTime? lastTriggeredAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SinggahMission(
      id: id,
      ownerId: ownerId,
      placeId: placeId ?? this.placeId,
      title: title ?? this.title,
      note: note ?? this.note,
      trigger: trigger ?? this.trigger,
      repeatDays: repeatDays ?? this.repeatDays,
      windowStartMinutes: windowStartMinutes ?? this.windowStartMinutes,
      windowEndMinutes: windowEndMinutes ?? this.windowEndMinutes,
      isActive: isActive ?? this.isActive,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    placeId,
    title,
    note,
    trigger,
    repeatDays,
    windowStartMinutes,
    windowEndMinutes,
    isActive,
    lastTriggeredAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
