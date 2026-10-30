import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart' as aw;
import 'package:appwrite/enums.dart' as awenums;
import 'package:appwrite/models.dart' as awmodels;
import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/domain/entities/social.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';

/// Appwrite-backed transport for the local-first repositories.
///
/// The SDK handles sessions and permissions. Row permissions are deliberately
/// written on create/upsert so a client can never read another account's Titik,
/// Misi, or Titipan.
class AppwriteCloudGateway implements CloudGateway {
  AppwriteCloudGateway(aw.Client client)
    : _client = client,
      _tables = aw.TablesDB(client),
      _functions = aw.Functions(client),
      _account = aw.Account(client),
      _realtime = aw.Realtime(client);

  final aw.Client _client;
  final aw.TablesDB _tables;
  final aw.Functions _functions;
  final aw.Account _account;
  final aw.Realtime _realtime;

  static const _databaseId = AppConfig.appwriteDatabaseId;

  @override
  bool get isDemo => false;

  @override
  Future<void> upsert(String table, Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return;
    final data = Map<String, dynamic>.from(row)
      ..remove('id')
      ..remove('is_pending');
    final existing = await _findRow(table, id);
    if (existing == null) {
      await _tables.createRow(
        databaseId: _databaseId,
        tableId: table,
        rowId: id,
        data: data,
        permissions: _permissionsFor(table, row),
      );
    } else {
      await _tables.updateRow(
        databaseId: _databaseId,
        tableId: table,
        rowId: id,
        data: data,
      );
    }
  }

  @override
  Future<void> softDelete(String table, String id, DateTime updatedAt) async {
    final timestamp = updatedAt.toUtc().toIso8601String();
    await _tables.updateRow(
      databaseId: _databaseId,
      tableId: table,
      rowId: id,
      data: {'deleted_at': timestamp, 'updated_at': timestamp},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> pull(
    String table, {
    DateTime? since,
    int limit = 200,
  }) async {
    final queries = <String>[
      if (since != null)
        aw.Query.greaterThan('updated_at', since.toUtc().toIso8601String()),
      aw.Query.orderAsc('updated_at'),
      aw.Query.limit(limit),
    ];
    final result = await _tables.listRows(
      databaseId: _databaseId,
      tableId: table,
      queries: queries,
    );
    return result.rows
        .map<Map<String, dynamic>>(_rowToMap)
        .toList(growable: false);
  }

  @override
  Stream<void> watchChanges(List<String> tables) {
    final channels = [
      for (final table in tables) 'tablesdb.$_databaseId.tables.$table.rows',
    ];
    return _watch(channels);
  }

  @override
  Stream<void> watchIncomingTitipan() {
    return _watch(['tablesdb.$_databaseId.tables.titipan_recipients.rows']);
  }

  @override
  Future<void> resetRealtime() => _realtime.disconnect();

  @override
  Future<SocialSnapshot> loadSocial() async {
    final me = (await _account.get()).$id;
    final friendships = await _tables.listRows(
      databaseId: _databaseId,
      tableId: 'friendships',
      queries: [aw.Query.limit(200)],
    );
    final groups = await _tables.listRows(
      databaseId: _databaseId,
      tableId: 'groups',
      queries: [aw.Query.limit(100)],
    );
    return SocialSnapshot(
      friendships: friendships.rows
          .map(_friendFromRow)
          .where((link) => link.requesterId == me || link.addresseeId == me)
          .toList(growable: false),
      groups: groups.rows.map(_groupFromRow).toList(growable: false),
    );
  }

  @override
  Future<void> requestFriend(String email) async {
    await _execute('social', {'action': 'request', 'email': email.trim()});
  }

  @override
  Future<void> respondFriendRequest(String id, {required bool accept}) async {
    await _execute('social', {'action': 'respond', 'id': id, 'accept': accept});
  }

  @override
  Future<FriendGroup> createGroup(String name, List<String> memberIds) async {
    final body = await _execute('social', {
      'action': 'createGroup',
      'name': name.trim(),
      'memberIds': memberIds,
    });
    return FriendGroup(
      id: body['id']?.toString() ?? '',
      ownerId: (await _account.get()).$id,
      name: body['name']?.toString() ?? name,
      memberIds: List<String>.from(memberIds),
    );
  }

  @override
  Future<void> deleteGroup(String id) async {
    await _execute('social', {'action': 'deleteGroup', 'id': id});
  }

  @override
  Future<void> updateGroup(
    String id, {
    required String name,
    required List<String> memberIds,
    required List<String> coOwnerIds,
  }) async {
    await _execute('social', {
      'action': 'updateGroup',
      'id': id,
      'name': name,
      'memberIds': memberIds,
      'coOwnerIds': coOwnerIds,
    });
  }

  @override
  Future<void> removeFriend(String id) async {
    await _execute('social', {'action': 'remove', 'id': id});
  }

  @override
  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    final result = await _tables.listRows(
      databaseId: _databaseId,
      tableId: 'messages',
      queries: [
        aw.Query.equal('conversation_id', conversationId),
        aw.Query.orderAsc('created_at'),
        aw.Query.limit(200),
      ],
    );
    return result.rows.map(_messageFromRow).toList(growable: false);
  }

  @override
  Stream<void> watchMessages() {
    // Dedicated socket: the sync engine resets its realtime connection on
    // auth changes, which would otherwise kill an open chat subscription.
    return Stream.multi((controller) {
      final realtime = aw.Realtime(_client);
      final subscription = realtime.subscribe([
        'tablesdb.$_databaseId.tables.messages.rows',
      ]);
      final inner = subscription.stream.listen(
        (_) => controller.add(null),
        onError: controller.addError,
      );
      controller.onCancel = () async {
        await inner.cancel();
        await subscription.unsubscribe();
        await realtime.disconnect();
      };
    });
  }

  @override
  Future<void> sendChatMessage({
    required String conversationId,
    required String body,
    required List<String> participantIds,
    required String senderName,
  }) async {
    await _execute('chat', {
      'conversationId': conversationId,
      'body': body,
      'participantIds': participantIds,
      'senderName': senderName,
    });
  }

  ChatMessage _messageFromRow(awmodels.Row row) {
    final data = row.data;
    return ChatMessage(
      id: row.$id,
      conversationId: data['conversation_id']?.toString() ?? '',
      senderId: data['sender_id']?.toString() ?? '',
      senderName: data['sender_name']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? ''),
    );
  }

  @override
  Future<int> sendTitipanDirect({
    required Map<String, dynamic> titipan,
    required List<String> friendIds,
    required List<String> groupIds,
  }) async {
    final body = await _execute('send-titipan', {
      'titipan': titipan,
      'friendIds': friendIds,
      'groupIds': groupIds,
    });
    return (body['recipients'] as num?)?.toInt() ?? 0;
  }

  FriendLink _friendFromRow(awmodels.Row row) {
    final data = row.data;
    return FriendLink(
      id: row.$id,
      requesterId: data['requester_id']?.toString() ?? '',
      requesterName: data['requester_name']?.toString() ?? '',
      requesterEmail: data['requester_email']?.toString() ?? '',
      addresseeId: data['addressee_id']?.toString() ?? '',
      addresseeEmail: data['addressee_email']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
    );
  }

  FriendGroup _groupFromRow(awmodels.Row row) {
    final data = row.data;
    final members = data['member_ids'];
    final coOwners = data['co_owner_ids'];
    return FriendGroup(
      id: row.$id,
      ownerId: data['owner_id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      memberIds: members is List
          ? members.map((id) => id.toString()).toList(growable: false)
          : const [],
      coOwnerIds: coOwners is List
          ? coOwners.map((id) => id.toString()).toList(growable: false)
          : const [],
    );
  }

  Stream<void> _watch(List<String> channels) {
    return Stream.multi((controller) {
      aw.RealtimeSubscription? subscription;
      try {
        subscription = _realtime.subscribe(channels);
        final inner = subscription.stream.listen(
          (_) => controller.add(null),
          onError: controller.addError,
        );
        controller.onCancel = () async {
          await inner.cancel();
          await subscription?.unsubscribe();
        };
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
        controller.close();
      }
    });
  }

  @override
  Future<Map<String, dynamic>> acceptTitipanInvite(String token) async {
    final body = await _execute(AppConfig.acceptTitipanFunction, {
      'token': token.trim(),
    });
    if (body['id'] == null && body['\$id'] != null) {
      body['id'] = body['\$id'];
    }
    return body;
  }

  @override
  Future<void> markTitipanRead(String titipanId) async {
    final user = await _account.get();
    final rows = await _tables.listRows(
      databaseId: _databaseId,
      tableId: 'titipan_recipients',
      queries: [
        aw.Query.equal('titipan_id', titipanId),
        aw.Query.equal('user_id', user.$id),
        aw.Query.limit(5),
      ],
    );
    final now = DateTime.now().toUtc().toIso8601String();
    for (final row in rows.rows) {
      await _tables.updateRow(
        databaseId: _databaseId,
        tableId: 'titipan_recipients',
        rowId: row.$id,
        data: {'read_at': now, 'updated_at': now},
      );
    }
  }

  @override
  Future<Map<String, dynamic>> parseNaturalReminder(
    String text, {
    required String localeCode,
  }) async {
    final body = await _execute(AppConfig.parseReminderFunction, {
      'text': text,
      'locale': localeCode,
    });
    final draft = body['draft'];
    if (draft is Map) return Map<String, dynamic>.from(draft);
    return body;
  }

  @override
  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    required String localeCode,
  }) async {
    final body = await _execute(AppConfig.geocodeFunction, {
      'mode': 'search',
      'q': query,
      'lang': localeCode,
    });
    final results = body['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map>()
        .map((row) {
          final display = row['display_name']?.toString() ?? '';
          return PlaceSuggestion(
            name: row['name']?.toString().trim().isNotEmpty == true
                ? row['name'].toString()
                : display.split(',').first.trim(),
            address: display,
            latitude: _asDouble(row['lat']),
            longitude: _asDouble(row['lon']),
            category: row['category']?.toString() ?? '',
          );
        })
        .where((place) => place.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<String?> reverseGeocode(
    double latitude,
    double longitude, {
    required String localeCode,
  }) async {
    final body = await _execute(AppConfig.geocodeFunction, {
      'mode': 'reverse',
      'lat': latitude,
      'lon': longitude,
      'lang': localeCode,
    });
    return body['address']?.toString();
  }

  @override
  Future<String?> uploadAvatar(List<int> bytes) async => null;

  // Appwrite Messaging can replace this later; local place notifications are
  // already handled by the native receiver.
  @override
  Future<void> registerDeviceToken(String token, String platform) async {
    final targetId = _targetIdFor(token);
    try {
      await _account.updatePushTarget(targetId: targetId, identifier: token);
      return;
    } on aw.AppwriteException catch (error) {
      if (error.code != 404) rethrow;
    }
    await _account.createPushTarget(
      targetId: targetId,
      identifier: token,
      providerId: AppConfig.pushProviderId.isEmpty
          ? null
          : AppConfig.pushProviderId,
    );
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    try {
      await _account.deletePushTarget(targetId: _targetIdFor(token));
    } on aw.AppwriteException catch (error) {
      if (error.code != 404) rethrow;
    }
  }

  /// Stable, URL-safe target id per FCM token (Appwrite limits ids to 36 chars).
  String _targetIdFor(String token) {
    var hash = 0;
    for (final unit in token.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return 'push_${hash.toRadixString(36)}';
  }

  Future<Map<String, dynamic>> _execute(
    String functionId,
    Map<String, dynamic> payload,
  ) async {
    final execution = await _functions.createExecution(
      functionId: functionId,
      body: jsonEncode(payload),
      method: awenums.ExecutionMethod.pOST,
    );
    final status = execution.responseStatusCode;
    Map<String, dynamic> body = const {};
    if (execution.responseBody.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(execution.responseBody);
        if (decoded is Map) body = Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Keep the status code as the source of truth.
      }
    }
    if (status < 200 || status >= 300) {
      throw DiscoveryException(
        body['error']?.toString() ?? 'Server error',
        rateLimited: status == 429 || status == 403,
      );
    }
    if (execution.status == awenums.ExecutionStatus.failed) {
      throw DiscoveryException(body['error']?.toString() ?? 'Function failed');
    }
    return body;
  }

  Future<awmodels.Row?> _findRow(String table, String id) async {
    try {
      return await _tables.getRow(
        databaseId: _databaseId,
        tableId: table,
        rowId: id,
      );
    } on aw.AppwriteException catch (error) {
      if (error.code == 404) return null;
      rethrow;
    }
  }

  Map<String, dynamic> _rowToMap(awmodels.Row row) {
    final map = Map<String, dynamic>.from(row.data);
    map['id'] = row.$id;
    return map;
  }

  List<String> _permissionsFor(String table, Map<String, dynamic> row) {
    final owner = row['owner_id'] ?? row['sender_id'] ?? row['user_id'] ?? '';
    final ownerId = owner.toString();
    if (ownerId.isEmpty) return const [];
    final permissions = [
      aw.Permission.read(aw.Role.user(ownerId)),
      aw.Permission.update(aw.Role.user(ownerId)),
      aw.Permission.delete(aw.Role.user(ownerId)),
    ];
    return permissions;
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
