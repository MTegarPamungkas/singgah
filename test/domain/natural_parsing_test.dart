import 'package:flutter_test/flutter_test.dart';

import 'package:singgah/domain/entities/natural_draft.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/usecases/heuristic_natural_parser.dart';

void main() {
  group('NaturalDraft.fromAiJson', () {
    test('parses a well-formed server response', () {
      final draft = NaturalDraft.fromAiJson({
        'title': 'Beli galon',
        'place_name': 'Alfamart dekat rumah',
        'trigger': 'leave',
        'repeat_days': [1, 2, 3, 8, 0],
        'window_start': '16:30',
        'window_end': '21:00',
        'confidence': 0.86,
        'address': 'Jl. Kemang',
        'note': 'Dua galon',
      }, rawText: 'ingetin beli galon');
      expect(draft.title, 'Beli galon');
      expect(draft.placeName, 'Alfamart dekat rumah');
      expect(draft.trigger, MissionTrigger.leave);
      expect(draft.repeatDays, {1, 2, 3});
      expect(draft.windowStartMinutes, 16 * 60 + 30);
      expect(draft.windowEndMinutes, 21 * 60);
      expect(draft.confidence, closeTo(0.86, 0.001));
      expect(draft.note, 'Dua galon');
    });

    test('accepts aliases and percentage confidence', () {
      final draft = NaturalDraft.fromAiJson({
        'placeName': 'Kantor',
        'trigger': 'keluar',
        'repeatDays': [6, 7],
        'windowStart': '08.00',
        'windowEnd': '09.15',
        'confidence': 75,
      }, rawText: 'ingat bawa laptop');
      expect(draft.title, 'ingat bawa laptop');
      expect(draft.placeName, 'Kantor');
      expect(draft.trigger, MissionTrigger.leave);
      expect(draft.repeatDays, {6, 7});
      expect(draft.windowStartMinutes, 8 * 60);
      expect(draft.windowEndMinutes, 9 * 60 + 15);
      expect(draft.confidence, closeTo(0.75, 0.001));
    });

    test('malformed fields fall back safely', () {
      final draft = NaturalDraft.fromAiJson({
        'title': '   ',
        'confidence': 'nonsense',
        'repeat_days': 'monday',
        'window_start': '25:99',
        'window_end': null,
      }, rawText: 'ingetin sesuatu');
      expect(draft.title, 'ingetin sesuatu');
      expect(draft.placeName, isEmpty);
      expect(draft.repeatDays, isEmpty);
      expect(draft.windowStartMinutes, 0);
      expect(draft.windowEndMinutes, 24 * 60 - 1);
      expect(draft.confidence, 0.5);
      expect(draft.isUsable, isTrue);
    });

    test('long fallback titles are truncated', () {
      final raw = 'a' * 120;
      final draft = NaturalDraft.fromAiJson({}, rawText: raw);
      expect(draft.title.length, 81);
      expect(draft.title.endsWith('…'), isTrue);
    });

    test('toJson round-trips the review fields', () {
      const draft = NaturalDraft(
        rawText: 'raw',
        title: 'Kirim laporan',
        placeName: 'Kantor',
        trigger: MissionTrigger.leave,
        repeatDays: {2, 1},
        windowStartMinutes: 60,
        windowEndMinutes: 120,
        confidence: 0.9,
      );
      final json = draft.toJson();
      final parsed = NaturalDraft.fromAiJson(json, rawText: 'raw');
      expect(parsed.title, draft.title);
      expect(parsed.placeName, draft.placeName);
      expect(parsed.trigger, draft.trigger);
      expect(parsed.repeatDays, {1, 2});
      expect(parsed.windowStartMinutes, 60);
      expect(parsed.windowEndMinutes, 120);
      expect(parsed.confidencePercent, 90);
    });
  });

  group('HeuristicNaturalParser', () {
    const parser = HeuristicNaturalParser();

    test('strips the lead phrase and recognises a place', () {
      final draft = parser.parse(
        'ingetin beli galon pas lewat Alfamart dekat rumah',
      );
      expect(draft.title.toLowerCase(), contains('beli galon'));
      expect(draft.placeName, 'Alfamart dekat rumah');
      expect(draft.trigger, MissionTrigger.arrive);
    });

    test('recognises leaving, weekdays, and a time window', () {
      final draft = parser.parse(
        'ingatkan bawa charger saat keluar rumah hari kerja jam 7-9',
      );
      expect(draft.trigger, MissionTrigger.leave);
      expect(draft.repeatDays, {1, 2, 3, 4, 5});
      expect(draft.windowStartMinutes, 7 * 60);
      expect(draft.windowEndMinutes, 9 * 60);
    });

    test('falls back to the raw sentence when nothing can be parsed', () {
      final draft = parser.parse('   ');
      expect(draft.title, isEmpty);
      expect(draft.isUsable, isFalse);
      expect(draft.confidence, closeTo(0.45, 0.001));
    });
  });
}
