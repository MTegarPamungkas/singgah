import 'package:singgah/data/services/geofence_coordinator.dart';
import 'package:singgah/data/services/push_token_coordinator.dart';
import 'package:singgah/data/services/titipan_notification_coordinator.dart';
import 'package:singgah/data/sync/sync_engine.dart';
import 'package:singgah/domain/services/notification_service.dart';

/// Small, idempotent jobs that keep the app honest when it resumes.
///
/// Everything here is best effort: a denied permission or a missing native
/// channel must never stop the user from managing Places, Missions, or Notes.
class AppMaintenance {
  AppMaintenance(
    this._geofences,
    this._notifications,
    this._inbox,
    this._push,
    this._sync,
  );

  final GeofenceCoordinator _geofences;
  final NotificationService _notifications;
  final TitipanNotificationCoordinator _inbox;
  final PushTokenCoordinator _push;
  final SyncEngine _sync;

  Future<void> start() async {
    try {
      await _notifications.init();
    } catch (_) {}
    await run();
  }

  Future<void> run() async {
    try {
      await _geofences.start();
      await _geofences.syncTransitions();
      await _geofences.refresh(force: true);
    } catch (_) {}
    try {
      await _inbox.start();
      await _inbox.checkInbox();
    } catch (_) {}
    try {
      await _push.start();
    } catch (_) {}
    try {
      _sync.requestSync();
    } catch (_) {}
  }
}
