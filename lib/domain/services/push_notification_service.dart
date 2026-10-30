abstract interface class PushNotificationService {
  /// False when the build has no Firebase configuration, on web, or on a
  /// platform without remote push support. Callers then rely on local
  /// notifications and the realtime inbox listener.
  bool get isConfigured;

  /// Initialises Firebase lazily and returns the current FCM token. Failures
  /// are non-fatal: place reminders must keep working without push.
  Future<String?> initializeAndGetToken();

  Stream<String> get tokenRefreshes;

  Future<void> dispose();
}
