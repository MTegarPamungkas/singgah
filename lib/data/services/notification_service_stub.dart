import 'package:singgah/domain/services/notification_service.dart';

NotificationService createNotificationService() => NotificationServiceStub();

class NotificationServiceStub implements NotificationService {
  @override
  bool get isSupported => false;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> showMission({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> showTitipan({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> cancelAll() async {}
}
