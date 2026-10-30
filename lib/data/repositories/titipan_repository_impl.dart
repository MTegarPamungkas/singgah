import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/core/utils/json_x.dart';
import 'package:singgah/core/utils/stream_combine.dart';
import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/mappers/entity_mappers.dart';
import 'package:singgah/data/repositories/local_repository_base.dart';
import 'package:singgah/data/sync/sync_engine.dart';
import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/entities/titipan_feed.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/repositories/titipan_repository.dart';

class TitipanRepositoryImpl extends LocalRepositoryBase
    implements TitipanRepository {
  TitipanRepositoryImpl(
    LocalStore store,
    SyncEngine sync,
    AuthRepository auth,
    CloudGateway gateway,
  ) : _gateway = gateway,
      super(store, sync, auth);

  final CloudGateway _gateway;

  @override
  Stream<TitipanFeed> watchFeed() {
    return combineLatest2(
      store.watch('titipan'),
      store.watch('titipan_recipients'),
      (
        List<Map<String, dynamic>> titipanRows,
        List<Map<String, dynamic>> recipientRows,
      ) {
        return TitipanFeed(
          titipans: titipanRows
              .map(titipanFromRow)
              .where((titipan) => !titipan.isDeleted)
              .toList(growable: false),
          recipients: recipientRows
              .map(recipientFromRow)
              .toList(growable: false),
        );
      },
    );
  }

  @override
  Future<TitipanFeed> getFeed() async {
    return TitipanFeed(
      titipans: store
          .all('titipan')
          .map(titipanFromRow)
          .where((titipan) => !titipan.isDeleted)
          .toList(growable: false),
      recipients: store
          .all('titipan_recipients')
          .map(recipientFromRow)
          .toList(growable: false),
    );
  }

  @override
  Future<Titipan?> getTitipan(String id) async {
    final row = store.get('titipan', id);
    if (row == null) return null;
    final titipan = titipanFromRow(row);
    return titipan.isDeleted ? null : titipan;
  }

  @override
  Future<void> saveTitipan(Titipan titipan) async {
    final now = DateTime.now();
    final payload = titipanToRow(
      Titipan(
        id: titipan.id,
        senderId: userId,
        senderName: titipan.senderName.trim(),
        placeId: titipan.placeId,
        placeName: titipan.placeName.trim(),
        latitude: titipan.latitude,
        longitude: titipan.longitude,
        radiusMeters: titipan.radiusMeters.clamp(100, 2000),
        title: titipan.title.trim(),
        body: titipan.body.trim(),
        trigger: titipan.trigger,
        inviteToken: titipan.inviteToken.isEmpty
            ? newId()
            : titipan.inviteToken,
        recipientHint: titipan.recipientHint.trim(),
        createdAt: titipan.createdAt ?? now,
        updatedAt: now,
      ),
    );
    await upsertRow('titipan', payload, updatedAt: now);
  }

  @override
  Future<void> deleteTitipan(String id) => softDeleteRow('titipan', id);

  @override
  Future<Titipan> acceptInvite(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) throw StateError('Invalid invite');
    final row = await _gateway.acceptTitipanInvite(trimmed);
    // Accepting is a server-validated operation; store the canonical row
    // without adding it to the outbox.
    await store.put('titipan', row);
    final acceptedAt = dateOrNull(row['accepted_at']) ?? DateTime.now();
    final recipient = TitipanRecipient(
      id: row['recipient_id']?.toString().isNotEmpty == true
          ? row['recipient_id'].toString()
          : newId(),
      titipanId: row['id'].toString(),
      userId: userId,
      invitedEmail: row['invited_email']?.toString(),
      acceptedAt: acceptedAt,
      createdAt: acceptedAt,
      updatedAt: acceptedAt,
    );
    await store.put('titipan_recipients', recipientToRow(recipient));
    sync.requestSync();
    return titipanFromRow(row);
  }

  @override
  Future<String> ensureInviteLink(Titipan titipan) async {
    var token = titipan.inviteToken;
    if (token.isEmpty) {
      token = newId();
      await saveTitipan(titipan.copyWith(inviteToken: token));
    }
    return AppConfig.inviteLink(token);
  }

  @override
  Future<void> markRead(String titipanId) async {
    final userIdValue = userId;
    for (final row in store.all('titipan_recipients')) {
      final recipient = recipientFromRow(row);
      if (recipient.titipanId != titipanId || recipient.userId != userIdValue) {
        continue;
      }
      final updated = recipient.copyWith(
        readAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await store.put('titipan_recipients', recipientToRow(updated));
    }
    await _gateway.markTitipanRead(titipanId);
  }

  @override
  Future<void> refresh() => sync.pullChanges();
}
