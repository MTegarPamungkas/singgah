import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:singgah/domain/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

NotificationService createNotificationService() => NotificationServiceIO();

class NotificationServiceIO implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Fall back to UTC if the platform cannot report a zone.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    const channels = [
      AndroidNotificationChannel(
        'singgah_alerts',
        'Singgah alerts',
        description: 'Reminders and Notes from Singgah',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'singgah_reminders',
        'Singgah reminders',
        description: 'Place-triggered Missions',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'singgah_titipan',
        'Titipan',
        description: 'Notes left at a Place',
        importance: Importance.high,
      ),
    ];
    for (final channel in channels) {
      await androidPlugin?.createNotificationChannel(channel);
    }
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  @override
  Future<void> showMission({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) => _show(id, title, body, payload, 'singgah_reminders');

  @override
  Future<void> showTitipan({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) => _show(id, title, body, payload, 'singgah_titipan');

  Future<void> _show(
    String id,
    String title,
    String body,
    String? payload,
    String channel,
  ) async {
    if (!isSupported) return;
    await init();
    await _plugin.show(
      id: id.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channel == 'singgah_reminders' ? 'Singgah reminders' : 'Titipan',
          channelDescription: 'Singgah time-and-place alerts',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(body),
          color: const Color(0xFFC94F0E),
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  @override
  Future<void> cancelAll() async {
    if (!isSupported) return;
    await init();
    await _plugin.cancelAll();
  }
}
