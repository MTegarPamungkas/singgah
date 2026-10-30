import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/domain/entities/app_user.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/services/push_notification_service.dart';

/// Keeps the FCM token attached to the signed-in account.
///
/// A token identifies a device, not a person. When a different account signs in
/// on the same device, registration reassigns the token; signing out removes it
/// so the previous user cannot keep receiving Titipan pushes.
class PushTokenCoordinator {
  PushTokenCoordinator({
    required LocalStore store,
    required AuthRepository auth,
    required CloudGateway gateway,
    required PushNotificationService push,
  }) : _store = store,
       _auth = auth,
       _gateway = gateway,
       _push = push;

  final LocalStore _store;
  final AuthRepository _auth;
  final CloudGateway _gateway;
  final PushNotificationService _push;

  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  String? _token;
  bool _started = false;
  bool _running = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _authSubscription = _auth.watchUser().listen(_onUser);
    if (_auth.currentUser != null) {
      await _register();
    }
  }

  void _listenForTokenRefreshes() {
    if (!_push.isConfigured || _tokenSubscription != null) return;
    _tokenSubscription = _push.tokenRefreshes.listen(_onToken);
  }

  Future<void> _onUser(AppUser? user) async {
    if (user == null) {
      await _unregister();
      return;
    }
    await _register();
  }

  Future<void> _onToken(String token) async {
    _token = token;
    await _store.setMeta('push_token', token);
    if (_auth.currentUser == null) return;
    try {
      await _gateway.registerDeviceToken(token, _platform);
    } catch (error) {
      debugPrint('Push token refresh could not be registered: $error');
    }
  }

  Future<void> _register() async {
    if (!_push.isConfigured || _running) return;
    _running = true;
    try {
      final token = await _push.initializeAndGetToken();
      if (token == null) return;
      _listenForTokenRefreshes();
      _token = token;
      await _store.setMeta('push_token', token);
      await _gateway.registerDeviceToken(token, _platform);
    } catch (error) {
      debugPrint('Push token registration skipped: $error');
    } finally {
      _running = false;
    }
  }

  Future<void> _unregister() async {
    final token = _token ?? _store.getMeta('push_token')?.toString();
    if (token == null || token.isEmpty) return;
    _token = null;
    try {
      await _gateway.unregisterDeviceToken(token);
    } catch (error) {
      debugPrint('Push token removal skipped: $error');
    } finally {
      await _store.removeMeta('push_token');
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _push.dispose();
    _started = false;
  }
}
