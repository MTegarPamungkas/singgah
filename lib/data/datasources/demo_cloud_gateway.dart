import 'dart:async';

import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/domain/entities/social.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';
import 'package:singgah/domain/usecases/heuristic_natural_parser.dart';
import 'package:uuid/uuid.dart';

/// Offline stand-in used when Appwrite is not configured. It deliberately does
/// not call third-party services: search returns a small curated list and the
/// AI step uses the deterministic heuristic parser.
class DemoCloudGateway implements CloudGateway {
  DemoCloudGateway({HeuristicNaturalParser? parser, Uuid? uuid})
    : _parser = parser ?? const HeuristicNaturalParser(),
      _uuid = uuid ?? const Uuid();

  final HeuristicNaturalParser _parser;
  final Uuid _uuid;

  static const List<PlaceSuggestion> _samples = [
    PlaceSuggestion(
      name: 'Alfamart dekat rumah',
      address: 'Jl. Kemang Raya No. 12, Jakarta Selatan',
      latitude: -6.2607,
      longitude: 106.8132,
      category: 'minimarket',
    ),
    PlaceSuggestion(
      name: 'Indomaret Sudirman',
      address: 'Jl. Jend. Sudirman Kav. 21, Jakarta Pusat',
      latitude: -6.2241,
      longitude: 106.8098,
      category: 'minimarket',
    ),
    PlaceSuggestion(
      name: 'Kampus UI Depok',
      address: 'Kampus Universitas Indonesia, Depok',
      latitude: -6.3606,
      longitude: 106.8272,
      category: 'campus',
    ),
    PlaceSuggestion(
      name: 'Stasiun Gambir',
      address: 'Jl. Medan Merdeka Timur, Jakarta Pusat',
      latitude: -6.1767,
      longitude: 106.8307,
      category: 'station',
    ),
    PlaceSuggestion(
      name: 'Kantor Sudirman',
      address: 'Jl. Jend. Sudirman Kav. 52, Jakarta Selatan',
      latitude: -6.2247,
      longitude: 106.8085,
      category: 'office',
    ),
    PlaceSuggestion(
      name: 'Toko Galon Pak Budi',
      address: 'Jl. Bangka Raya No. 8, Jakarta Selatan',
      latitude: -6.2433,
      longitude: 106.8178,
      category: 'shop',
    ),
  ];

  @override
  bool get isDemo => true;

  @override
  Future<void> upsert(String table, Map<String, dynamic> row) async {}

  @override
  Future<void> softDelete(String table, String id, DateTime updatedAt) async {}

  @override
  Future<List<Map<String, dynamic>>> pull(
    String table, {
    DateTime? since,
    int limit = 200,
  }) async => const [];

  @override
  Stream<void> watchChanges(List<String> tables) => const Stream<void>.empty();

  @override
  Stream<void> watchIncomingTitipan() => const Stream<void>.empty();

  @override
  Future<void> resetRealtime() async {}

  @override
  Future<SocialSnapshot> loadSocial() async {
    return SocialSnapshot(
      friendships: List<FriendLink>.from(_friendships),
      groups: List<FriendGroup>.from(_groups),
    );
  }

  @override
  Future<void> requestFriend(String email) async {
    final value = email.trim().toLowerCase();
    if (!value.contains('@')) throw StateError('Invalid email');
    _friendships.add(
      FriendLink(
        id: _uuid.v4(),
        requesterId: 'demo-user',
        requesterName: 'Kamu',
        requesterEmail: 'demo@singgah.app',
        addresseeId: _uuid.v4(),
        addresseeEmail: value,
        status: 'pending',
      ),
    );
  }

  @override
  Future<void> respondFriendRequest(String id, {required bool accept}) async {
    final index = _friendships.indexWhere((link) => link.id == id);
    if (index < 0) return;
    if (!accept) {
      _friendships.removeAt(index);
      return;
    }
    final current = _friendships[index];
    _friendships[index] = FriendLink(
      id: current.id,
      requesterId: current.requesterId,
      requesterName: current.requesterName,
      requesterEmail: current.requesterEmail,
      addresseeId: current.addresseeId,
      addresseeEmail: current.addresseeEmail,
      status: 'accepted',
    );
  }

  @override
  Future<FriendGroup> createGroup(String name, List<String> memberIds) async {
    final group = FriendGroup(
      id: _uuid.v4(),
      ownerId: 'demo-user',
      name: name.trim(),
      memberIds: List<String>.from(memberIds),
    );
    _groups.add(group);
    return group;
  }

  @override
  Future<void> deleteGroup(String id) async {
    _groups.removeWhere((group) => group.id == id);
  }

  @override
  Future<void> updateGroup(
    String id, {
    required String name,
    required List<String> memberIds,
    required List<String> coOwnerIds,
  }) async {
    final index = _groups.indexWhere((group) => group.id == id);
    if (index < 0) return;
    final current = _groups[index];
    _groups[index] = FriendGroup(
      id: current.id,
      ownerId: current.ownerId,
      name: name.trim(),
      memberIds: List<String>.from(memberIds),
      coOwnerIds: List<String>.from(coOwnerIds),
    );
  }

  @override
  Future<void> removeFriend(String id) async {
    _friendships.removeWhere((link) => link.id == id);
  }

  @override
  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    return _messages
        .where((message) => message.conversationId == conversationId)
        .toList(growable: false);
  }

  @override
  Stream<void> watchMessages() => const Stream<void>.empty();

  @override
  Future<void> sendChatMessage({
    required String conversationId,
    required String body,
    required List<String> participantIds,
    required String senderName,
  }) async {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        conversationId: conversationId,
        senderId: 'demo-user',
        senderName: senderName,
        body: body.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<int> sendTitipanDirect({
    required Map<String, dynamic> titipan,
    required List<String> friendIds,
    required List<String> groupIds,
  }) async {
    final members = <String>{
      ...friendIds,
      for (final group in _groups)
        if (groupIds.contains(group.id)) ...group.memberIds,
    };
    return members.length;
  }

  final List<FriendLink> _friendships = [];
  final List<FriendGroup> _groups = [];
  final List<ChatMessage> _messages = [];

  @override
  Future<Map<String, dynamic>> acceptTitipanInvite(String token) async {
    if (token.trim().isEmpty) {
      throw StateError('Invalid invite');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': _uuid.v4(),
      'sender_id': 'demo-sender-rani',
      'sender_name': 'Rani',
      'place_id': null,
      'place_name': 'Alfamart dekat rumah',
      'latitude': -6.2607,
      'longitude': 106.8132,
      'radius_meters': 150,
      'title': 'Ambil pesanan yang dititipkan',
      'body': 'Paket kecil ada di kasir. Sebut nama Rani ya.',
      'trigger': 'arrive',
      'invite_token': token,
      'recipient_hint': 'Demo',
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    };
  }

  @override
  Future<void> markTitipanRead(String titipanId) async {}

  @override
  Future<Map<String, dynamic>> parseNaturalReminder(
    String text, {
    required String localeCode,
  }) async {
    final draft = _parser.parse(text, localeCode: localeCode);
    return draft.toJson();
  }

  @override
  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    required String localeCode,
  }) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return _samples;
    return _samples
        .where(
          (place) =>
              place.name.toLowerCase().contains(needle) ||
              place.address.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  @override
  Future<String?> reverseGeocode(
    double latitude,
    double longitude, {
    required String localeCode,
  }) async {
    return 'Titik pilihan (${latitude.toStringAsFixed(4)}, '
        '${longitude.toStringAsFixed(4)})';
  }

  @override
  Future<String?> uploadAvatar(List<int> bytes) async => null;

  @override
  Future<void> registerDeviceToken(String token, String platform) async {}

  @override
  Future<void> unregisterDeviceToken(String token) async {}
}
