import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/sync/sync_engine.dart';
import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/repositories/titipan_repository.dart';
import 'package:singgah/domain/services/notification_service.dart';
import 'package:singgah/domain/services/push_notification_service.dart';
import 'package:singgah/domain/usecases/titipan_visibility.dart';

/// Surfaces Titipan that arrive while the app is open.
///
/// Place-triggered Notes are posted by the native geofence receiver. This
/// coordinator only covers the realtime case, de-duplicating with a per-Note
/// meta flag so a rebuild or reconnect does not notify twice.
class TitipanNotificationCoordinator {
  TitipanNotificationCoordinator({
    required LocalStore store,
    required SyncEngine sync,
    required TitipanRepository titipan,
    required AuthRepository auth,
    required NotificationService notifications,
    PushNotificationService? push,
  }) : _store = store,
       _sync = sync,
       _titipan = titipan,
       _auth = auth,
       _notifications = notifications,
       _push = push;

  final LocalStore _store;
  final SyncEngine _sync;
  final TitipanRepository _titipan;
  final AuthRepository _auth;
  final NotificationService _notifications;
  final PushNotificationService? _push;

  StreamSubscription<void>? _subscription;
  bool _started = false;
  bool _running = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _subscription = _sync.incomingTitipan.listen((_) => checkInbox());
    await checkInbox();
  }

  Future<int> checkInbox() async {
    if (_running) return 0;
    final user = _auth.currentUser;
    if (user == null || !_notifications.isSupported) return 0;
    _running = true;
    var shown = 0;
    try {
      final feed = await _titipan.getFeed();
      final inbox = TitipanVisibility.inbox(
        titipans: feed.titipans,
        recipients: feed.recipients,
        userId: user.id,
      );
      for (final titipan in inbox) {
        final key = 'notified_titipan_${titipan.id}';
        if (_store.getMeta(key) == true) continue;
        if (_isRead(titipan, feed.recipients, user.id)) {
          await _store.setMeta(key, true);
          continue;
        }
        final appResumed =
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
        if (!appResumed && (_push?.isConfigured ?? false)) {
          // Remote push owns the notification while the app is in the
          // background. Record the dedupe key so resuming does not show a
          // second local notification for the same note.
          await _store.setMeta(key, true);
          continue;
        }
        await _notifications.showTitipan(
          id: titipan.id,
          title: titipan.title,
          body: titipan.placeName.isEmpty
              ? titipan.body
              : '${titipan.placeName} · ${titipan.body}',
          payload: 'titipan:${titipan.id}',
        );
        await _store.setMeta(key, true);
        shown++;
      }
    } catch (_) {
      // A missed notification is better than blocking sync.
    } finally {
      _running = false;
    }
    return shown;
  }

  bool _isRead(
    Titipan titipan,
    List<TitipanRecipient> recipients,
    String userId,
  ) {
    for (final recipient in recipients) {
      if (recipient.titipanId != titipan.id || recipient.userId != userId) {
        continue;
      }
      return recipient.readAt != null;
    }
    return false;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
