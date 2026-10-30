import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  DateTime get dateOnly => DateTime(year, month, day);

  DateTime get startOfWeek {
    final monday = subtract(Duration(days: weekday - DateTime.monday));
    return DateTime(monday.year, monday.month, monday.day);
  }
}

String formatDate(DateTime value, String localeCode) =>
    DateFormat.yMMMEd(localeCode).format(value.toLocal());

String formatDateShort(DateTime value, String localeCode) =>
    DateFormat.MMMd(localeCode).format(value.toLocal());

String formatTime(DateTime value, String localeCode) =>
    DateFormat.Hm(localeCode).format(value.toLocal());

String formatDateTime(DateTime value, String localeCode) =>
    DateFormat.yMMMEd(localeCode).add_Hm().format(value.toLocal());

String relativeDay(DateTime value, DateTime now) {
  final today = now.dateOnly;
  final day = value.dateOnly;
  final difference = day.difference(today).inDays;
  if (difference == 0) return 'today';
  if (difference == -1) return 'yesterday';
  if (difference > 0 && difference < 7) return 'soon';
  return 'older';
}

String greetingKey(DateTime now) {
  final hour = now.hour;
  if (hour < 11) return 'morning';
  if (hour < 15) return 'afternoon';
  return 'evening';
}

String minutesToClock(int minutes) {
  final normalized = minutes.clamp(0, 24 * 60 - 1);
  final hour = normalized ~/ 60;
  final minute = normalized % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

int clockToMinutes(int hour, int minute) =>
    (hour.clamp(0, 23) * 60 + minute.clamp(0, 59));

/// Parses `HH:mm` or `H:mm`. Returns null for malformed input.
int? tryParseClock(String value) {
  final match = RegExp(r'^\s*(\d{1,2})\s*[:.]\s*(\d{2})\s*$').firstMatch(value);
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}

/// True when [minutes] sits inside a possibly overnight window.
bool minutesInWindow(
  int minutes, {
  required int start,
  required int end,
  bool inclusiveEnd = true,
}) {
  final s = start.clamp(0, 24 * 60 - 1);
  final e = end.clamp(0, 24 * 60 - 1);
  if (s == e) return true;
  if (s < e) {
    return inclusiveEnd
        ? minutes >= s && minutes <= e
        : minutes >= s && minutes < e;
  }
  // Overnight window, e.g. 22:00 → 02:00.
  return minutes >= s || (inclusiveEnd ? minutes <= e : minutes < e);
}

String distanceLabel(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
}
