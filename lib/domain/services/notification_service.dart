abstract interface class NotificationService {
  bool get isSupported;

  Future<void> init();

  Future<bool> requestPermission();

  Future<void> showMission({
    required String id,
    required String title,
    required String body,
    String? payload,
  });

  Future<void> showTitipan({
    required String id,
    required String title,
    required String body,
    String? payload,
  });

  Future<void> cancelAll();
}
