import 'package:singgah/domain/services/push_notification_service.dart';

PushNotificationService createPushNotificationService() =>
    PushNotificationServiceStub();

class PushNotificationServiceStub implements PushNotificationService {
  @override
  bool get isConfigured => false;

  @override
  Future<String?> initializeAndGetToken() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream<String>.empty();

  @override
  Future<void> dispose() async {}
}
