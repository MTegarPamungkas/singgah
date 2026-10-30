import 'package:singgah/domain/entities/social.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';

abstract interface class CloudGateway {
  bool get isDemo;

  Future<void> upsert(String table, Map<String, dynamic> row);

  Future<void> softDelete(String table, String id, DateTime updatedAt);

  Future<List<Map<String, dynamic>>> pull(
    String table, {
    DateTime? since,
    int limit = 200,
  });

  Stream<void> watchChanges(List<String> tables);

  Stream<void> watchIncomingTitipan();

  /// Drops any open realtime connection so the next subscription handshakes
  /// with the current session. Called after sign-in and sign-out.
  Future<void> resetRealtime();

  Future<Map<String, dynamic>> acceptTitipanInvite(String token);

  Future<void> markTitipanRead(String titipanId);

  Future<Map<String, dynamic>> parseNaturalReminder(
    String text, {
    required String localeCode,
  });

  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    required String localeCode,
  });

  Future<String?> reverseGeocode(
    double latitude,
    double longitude, {
    required String localeCode,
  });

  Future<String?> uploadAvatar(List<int> bytes);

  /// Registers/reassigns a push token to the current account.
  Future<void> registerDeviceToken(String token, String platform);

  /// Removes a push token belonging to the current account.
  Future<void> unregisterDeviceToken(String token);

  /// Friendships and groups visible to the signed-in account.
  Future<SocialSnapshot> loadSocial();

  Future<void> requestFriend(String email);

  Future<void> respondFriendRequest(String id, {required bool accept});

  Future<FriendGroup> createGroup(String name, List<String> memberIds);

  Future<void> updateGroup(
    String id, {
    required String name,
    required List<String> memberIds,
    required List<String> coOwnerIds,
  });

  Future<void> deleteGroup(String id);

  /// Removes a friendship or pending request.
  Future<void> removeFriend(String id);

  Future<List<ChatMessage>> loadMessages(String conversationId);

  /// Emits when any chat message changes; subscribers reload their thread.
  Stream<void> watchMessages();

  Future<void> sendChatMessage({
    required String conversationId,
    required String body,
    required List<String> participantIds,
    required String senderName,
  });

  /// Sends a Titipan directly to friends and/or groups. Returns the number of
  /// recipients the server created.
  Future<int> sendTitipanDirect({
    required Map<String, dynamic> titipan,
    required List<String> friendIds,
    required List<String> groupIds,
  });
}
