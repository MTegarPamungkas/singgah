import 'package:singgah/domain/entities/natural_draft.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';

/// Deterministic fallback used in demo mode and when the AI function is not
/// configured. It is intentionally modest: the user still reviews every field.
class HeuristicNaturalParser {
  const HeuristicNaturalParser();

  NaturalDraft parse(String rawText, {String localeCode = 'id'}) {
    final text = rawText.trim();
    final lower = text.toLowerCase();
    var title = text;
    var placeName = '';
    var trigger = MissionTrigger.arrive;
    var days = <int>{};
    var start = 0;
    var end = 24 * 60 - 1;

    final lead = RegExp(
      r'^(tolong\s+)?(ing[eé]t(?:in|kan)|ingatkan|remind\s+me\s+to|remind\s+to)\s+',
      caseSensitive: false,
    );
    title = title.replaceFirst(lead, '').trim();

    final leavePattern = RegExp(
      r'(pas\s+keluar|saat\s+keluar|meninggalkan|sebelum\s+pergi|after\s+leaving|when\s+leaving|on\s+exit)',
      caseSensitive: false,
    );
    if (leavePattern.hasMatch(lower)) trigger = MissionTrigger.leave;

    final placePatterns = [
      RegExp(
        r"(?:pas\s+lewat|saat\s+lewat|lewat|near|at|di\s+dekat|dekat|di)\s+([A-Za-z0-9À-ÿ'\.\-\s]{2,60})",
        caseSensitive: false,
      ),
    ];
    for (final pattern in placePatterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final candidate = match.group(1)!.trim();
      final cleaned = candidate
          .replaceAll(
            RegExp(
              r'\b(pas|saat|kalau|when|if|jam|pukul|setiap|every)\b.*$',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      if (cleaned.isNotEmpty) {
        placeName = cleaned;
        title = title.replaceFirst(match.group(0)!, '').trim();
        break;
      }
    }

    if (RegExp(
      r'\b(hari\s+kerja|weekdays?)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      days = {1, 2, 3, 4, 5};
    } else if (RegExp(
      r'\b(akhir\s+pekan|weekends?)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      days = {6, 7};
    }

    final window = RegExp(
      r'(?:jam|pukul|at)\s*(\d{1,2})(?:[:.](\d{2}))?\s*(?:-|sampai|to|hingga|s/d)\s*(\d{1,2})(?:[:.](\d{2}))?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (window != null) {
      final sh = int.tryParse(window.group(1)!);
      final sm = int.tryParse(window.group(2) ?? '0') ?? 0;
      final eh = int.tryParse(window.group(3)!);
      final em = int.tryParse(window.group(4) ?? '0') ?? 0;
      if (sh != null && eh != null && sh <= 23 && eh <= 23) {
        start = sh * 60 + sm.clamp(0, 59);
        end = eh * 60 + em.clamp(0, 59);
      }
    }

    title = title
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[,\.\-\s]+|[,\.\-\s]+$'), '')
        .trim();
    if (title.isEmpty) title = text;

    placeName = placeName
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[,\.\-\s]+|[,\.\-\s]+$'), '')
        .trim();

    return NaturalDraft(
      rawText: rawText,
      title: _sentenceCase(title),
      placeName: _sentenceCase(placeName),
      trigger: trigger,
      repeatDays: days,
      windowStartMinutes: start,
      windowEndMinutes: end,
      confidence: 0.45,
    );
  }

  String _sentenceCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
