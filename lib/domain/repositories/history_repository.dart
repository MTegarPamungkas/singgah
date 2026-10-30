import 'package:singgah/domain/entities/singgah_event.dart';

abstract interface class HistoryRepository {
  Stream<List<SinggahEvent>> watchEvents();

  Future<List<SinggahEvent>> getEvents();

  Future<void> record(SinggahEvent event);

  Future<void> clear();

  /// Drains transitions buffered by the Android broadcast receiver while the
  /// app was closed. Returns the number of newly recorded events.
  Future<int> drainNativeTransitions();
}
