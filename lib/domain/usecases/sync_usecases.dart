import 'package:singgah/domain/entities/sync_status.dart';
import 'package:singgah/domain/repositories/sync_repository.dart';

class WatchSyncStatus {
  const WatchSyncStatus(this._repository);
  final SyncRepository _repository;

  Stream<SyncStatus> call() => _repository.watchStatus();
}

class SyncNow {
  const SyncNow(this._repository);
  final SyncRepository _repository;

  Future<void> call() => _repository.syncNow();
}

class RequestSync {
  const RequestSync(this._repository);
  final SyncRepository _repository;

  void call() => _repository.requestSync();
}
