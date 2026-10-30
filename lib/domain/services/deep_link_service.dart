abstract interface class DeepLinkService {
  /// Fires when the app receives `singgah://invite/<token>` or an https link
  /// whose path contains `/invite/<token>`.
  Stream<String> get inviteTokens;

  Future<String?> initialInviteToken();

  Future<void> dispose();
}
