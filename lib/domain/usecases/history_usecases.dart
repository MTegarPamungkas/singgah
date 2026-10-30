import 'package:singgah/domain/entities/singgah_event.dart';
import 'package:singgah/domain/repositories/history_repository.dart';

class WatchHistory {
  const WatchHistory(this._repository);
  final HistoryRepository _repository;

  Stream<List<SinggahEvent>> call() => _repository.watchEvents();
}

class RecordSinggahEvent {
  const RecordSinggahEvent(this._repository);
  final HistoryRepository _repository;

  Future<void> call(SinggahEvent event) => _repository.record(event);
}

class ClearHistory {
  const ClearHistory(this._repository);
  final HistoryRepository _repository;

  Future<void> call() => _repository.clear();
}

class DrainNativeTransitions {
  const DrainNativeTransitions(this._repository);
  final HistoryRepository _repository;

  Future<int> call() => _repository.drainNativeTransitions();
}
