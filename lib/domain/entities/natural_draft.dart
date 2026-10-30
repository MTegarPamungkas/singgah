import 'package:equatable/equatable.dart';

import 'package:singgah/core/utils/date_time_x.dart';
import 'package:singgah/core/utils/json_x.dart';

import 'singgah_mission.dart';

/// Structured result of the natural-language step. It is intentionally a
/// *draft*: the user reviews every field before anything is written locally.
class NaturalDraft extends Equatable {
  const NaturalDraft({
    required this.rawText,
    required this.title,
    required this.placeName,
    this.trigger = MissionTrigger.arrive,
    this.repeatDays = const {},
    this.windowStartMinutes = 0,
    this.windowEndMinutes = 24 * 60 - 1,
    this.confidence = 0.5,
    this.address = '',
    this.note = '',
  });

  final String rawText;
  final String title;
  final String placeName;
  final MissionTrigger trigger;
  final Set<int> repeatDays;
  final int windowStartMinutes;
  final int windowEndMinutes;
  final double confidence;
  final String address;
  final String note;

  bool get isUsable => title.trim().isNotEmpty;

  int get confidencePercent => (confidence.clamp(0, 1) * 100).round();

  NaturalDraft copyWith({
    String? title,
    String? placeName,
    MissionTrigger? trigger,
    Set<int>? repeatDays,
    int? windowStartMinutes,
    int? windowEndMinutes,
    double? confidence,
    String? address,
    String? note,
  }) {
    return NaturalDraft(
      rawText: rawText,
      title: title ?? this.title,
      placeName: placeName ?? this.placeName,
      trigger: trigger ?? this.trigger,
      repeatDays: repeatDays ?? this.repeatDays,
      windowStartMinutes: windowStartMinutes ?? this.windowStartMinutes,
      windowEndMinutes: windowEndMinutes ?? this.windowEndMinutes,
      confidence: confidence ?? this.confidence,
      address: address ?? this.address,
      note: note ?? this.note,
    );
  }

  /// Parses a server response defensively. Unknown or malformed fields fall
  /// back to safe defaults instead of making the whole feature fail.
  factory NaturalDraft.fromAiJson(
    Map<String, dynamic> json, {
    required String rawText,
    String localeCode = 'id',
  }) {
    final fallbackTitle = rawText.trim().length > 80
        ? '${rawText.trim().substring(0, 80)}…'
        : rawText.trim();
    final title = stringOr(json['title'], fallbackTitle).trim();
    final placeName = stringOr(
      json['place_name'] ?? json['placeName'] ?? json['place'],
    ).trim();
    final triggerRaw = stringOr(json['trigger']).toLowerCase().trim();
    final trigger = switch (triggerRaw) {
      'leave' ||
      'exit' ||
      'pergi' ||
      'keluar' ||
      'meninggalkan' => MissionTrigger.leave,
      _ => MissionTrigger.arrive,
    };
    final days = intSet(json['repeat_days'] ?? json['repeatDays']);
    final start = tryParseClock(
      stringOr(json['window_start'] ?? json['windowStart'], '00:00'),
    );
    final end = tryParseClock(
      stringOr(json['window_end'] ?? json['windowEnd'], '23:59'),
    );
    final confidenceRaw = doubleOr(json['confidence'], 0.5);

    return NaturalDraft(
      rawText: rawText,
      title: title.isEmpty ? fallbackTitle : title,
      placeName: placeName,
      trigger: trigger,
      repeatDays: days,
      windowStartMinutes: start ?? 0,
      windowEndMinutes: end ?? 24 * 60 - 1,
      confidence: confidenceRaw > 1
          ? (confidenceRaw / 100).clamp(0, 1)
          : confidenceRaw.clamp(0, 1),
      address: stringOr(json['address']).trim(),
      note: stringOr(json['note']).trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'place_name': placeName,
    'trigger': trigger.name,
    'repeat_days': (repeatDays.toList()..sort()),
    'window_start': minutesToClock(windowStartMinutes),
    'window_end': minutesToClock(windowEndMinutes),
    'confidence': confidence,
    'address': address,
    'note': note,
  };

  @override
  List<Object?> get props => [
    rawText,
    title,
    placeName,
    trigger,
    repeatDays,
    windowStartMinutes,
    windowEndMinutes,
    confidence,
    address,
    note,
  ];
}
