import 'package:singgah/domain/services/deep_link_service.dart';

DeepLinkService createDeepLinkService() => DeepLinkServiceStub();

class DeepLinkServiceStub implements DeepLinkService {
  @override
  Stream<String> get inviteTokens => const Stream<String>.empty();

  @override
  Future<String?> initialInviteToken() async => null;

  @override
  Future<void> dispose() async {}
}
