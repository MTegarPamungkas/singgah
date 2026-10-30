import 'package:flutter/foundation.dart';

/// Compile-time configuration.
///
/// Values are injected with `--dart-define-from-file=env.json`. API keys for
/// AI and geocoding never live here: both are proxied by Appwrite Functions.
abstract final class AppConfig {
  static const String appName = 'Singgah';
  static const String tagline = 'Diingetin pas di tempatnya, bukan pas lupa.';
  static const String appScheme = String.fromEnvironment(
    'APP_SCHEME',
    defaultValue: 'dev.singgah',
  );

  /// Public Appwrite endpoint. On the Android emulator `localhost` is the
  /// emulator itself, so it is mapped to the host loopback address.
  static const String appwriteEndpointRaw = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'http://localhost/v1',
  );
  static const String appwriteProjectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
  );
  static const String appwriteDatabaseId = 'singgah';
  static const String appwriteAvatarBucket = 'avatars';
  static const String acceptTitipanFunction = 'accept-titipan';
  static const String parseReminderFunction = 'parse-reminder';
  static const String geocodeFunction = 'geocode';
  static const String notifyTitipanFunction = 'notify-titipan';

  /// Appwrite Messaging FCM provider used for device push targets.
  static const String pushProviderId = String.fromEnvironment(
    'APPWRITE_PUSH_PROVIDER_ID',
  );

  /// Enabled after the Google provider is configured in Appwrite.
  static const bool googleAuthEnabled = bool.fromEnvironment(
    'GOOGLE_AUTH_ENABLED',
  );

  static String get appwriteEndpoint {
    final raw = appwriteEndpointRaw.trim();
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        raw.contains('localhost')) {
      return raw.replaceFirst('localhost', '10.0.2.2');
    }
    return raw;
  }

  static bool get hasAppwrite => appwriteProjectId.trim().isNotEmpty;

  /// Public URL used for shareable invitation links on web builds. On Android
  /// the custom scheme is preferred so the app opens directly.
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://singgah.app',
  );

  /// Optional Firebase Cloud Messaging configuration. When absent, the app
  /// still posts local notifications but cannot receive remote pushes while
  /// fully closed.
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );

  static bool get hasFirebase =>
      !kIsWeb &&
      firebaseProjectId.trim().isNotEmpty &&
      firebaseAppId.trim().isNotEmpty &&
      firebaseApiKey.trim().isNotEmpty &&
      firebaseMessagingSenderId.trim().isNotEmpty;

  static const String demoEmail = 'demo@singgah.app';
  static const String demoName = 'Tamu Singgah';
  static const String demoUserId = '00000000-0000-4000-8000-000000000002';

  /// Android allows roughly 100 geofences per app. Keep headroom for system
  /// reservations and other libraries.
  static const int maxGeofences = 90;

  static String get oauthRedirectUrl {
    if (kIsWeb) return webOauthRedirect(Uri.base);
    return '$appScheme://login-callback';
  }

  static String inviteLink(String token) {
    if (kIsWeb) {
      // The web build uses hash routing, so the link must carry the route in
      // the fragment. Static hosts (GitHub Pages, Netlify) then serve
      // index.html and go_router opens the invitation directly.
      final base = webBaseUrl.endsWith('/') ? webBaseUrl : '$webBaseUrl/';
      return '$base#/invite/$token';
    }
    return '$appScheme://invite/$token';
  }

  /// Returns the directory the web app is served from, with a trailing slash.
  /// GitHub Pages hosts the app under `/<repo>/` so `Uri.base.origin` alone
  /// would drop the path and land outside the app.
  @visibleForTesting
  static String webOauthRedirect(Uri base) => base.resolve('.').toString();

  /// Geofencing is an Android capability. Web only manages Titik, Misi, and
  /// Titipan, and explains why live place triggers are unavailable.
  static bool get supportsGeofencing =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
