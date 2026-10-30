import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/domain/services/push_notification_service.dart';

PushNotificationService createPushNotificationService() =>
    PushNotificationServiceIO();

class PushNotificationServiceIO implements PushNotificationService {
  @override
  bool get isConfigured =>
      AppConfig.hasFirebase && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<String?> initializeAndGetToken() async {
    if (!isConfigured) return null;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: AppConfig.firebaseApiKey,
            appId: AppConfig.firebaseAppId,
            messagingSenderId: AppConfig.firebaseMessagingSenderId,
            projectId: AppConfig.firebaseProjectId,
          ),
        );
      }
      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      // ignore: deprecated_member_use
      return await messaging.getToken();
    } catch (error) {
      debugPrint('FCM initialization skipped: $error');
      return null;
    }
  }

  @override
  Stream<String> get tokenRefreshes {
    // ignore: deprecated_member_use
    return FirebaseMessaging.instance.onTokenRefresh;
  }

  @override
  Future<void> dispose() async {}
}
