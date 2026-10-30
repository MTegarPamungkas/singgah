import 'package:singgah/domain/entities/sync_status.dart';

abstract interface class SyncRepository {
  SyncStatus get current;

  Stream<SyncStatus> watchStatus();

  Future<void> syncNow();

  void requestSync();
}
