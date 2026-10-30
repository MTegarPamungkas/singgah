/// Social graph entities: friendships and private groups.
class FriendLink {
  const FriendLink({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.addresseeId,
    required this.addresseeEmail,
    required this.status,
  });

  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String addresseeId;
  final String addresseeEmail;
  final String status;

  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';

  String otherId(String me) => requesterId == me ? addresseeId : requesterId;

  String otherName(String me) {
    if (requesterId == me) {
      return addresseeEmail.split('@').first;
    }
    return requesterName.isEmpty
        ? requesterEmail.split('@').first
        : requesterName;
  }

  String otherEmail(String me) =>
      requesterId == me ? addresseeEmail : requesterEmail;
}

class FriendGroup {
  const FriendGroup({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.memberIds,
    this.coOwnerIds = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final List<String> memberIds;
  final List<String> coOwnerIds;

  bool contains(String userId) =>
      ownerId == userId ||
      memberIds.contains(userId) ||
      coOwnerIds.contains(userId);

  bool canEdit(String userId) =>
      ownerId == userId || coOwnerIds.contains(userId);

  /// Everyone who should receive messages in this group chat.
  List<String> get chatParticipantIds => {
    ...[ownerId],
    ...coOwnerIds,
    ...memberIds,
  }.toList(growable: false);
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime? createdAt;
}

/// Deterministic 1:1 conversation id. Must match `expectedDmId` in the
/// `chat` Appwrite Function.
String dmConversationId(String a, String b) {
  final ids = [a, b]..sort();
  var hash = 0x811c9dc5;
  for (final unit in ids.join(':').codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return 'dm_${hash.toRadixString(16).padLeft(8, '0')}';
}

class SocialSnapshot {
  const SocialSnapshot({this.friendships = const [], this.groups = const []});

  final List<FriendLink> friendships;
  final List<FriendGroup> groups;

  List<FriendLink> friendsFor(String me) => friendships
      .where((link) => link.isAccepted && link.otherId(me).isNotEmpty)
      .toList(growable: false);

  List<FriendLink> incomingFor(String me) => friendships
      .where((link) => link.isPending && link.addresseeId == me)
      .toList(growable: false);

  List<FriendLink> outgoingFor(String me) => friendships
      .where((link) => link.isPending && link.requesterId == me)
      .toList(growable: false);

  List<FriendGroup> groupsFor(String me) =>
      groups.where((group) => group.contains(me)).toList(growable: false);

  bool get isEmpty => friendships.isEmpty && groups.isEmpty;
}
