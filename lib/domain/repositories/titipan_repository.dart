import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/entities/titipan_feed.dart';

abstract interface class TitipanRepository {
  Stream<TitipanFeed> watchFeed();

  Future<TitipanFeed> getFeed();

  Future<Titipan?> getTitipan(String id);

  Future<void> saveTitipan(Titipan titipan);

  Future<void> deleteTitipan(String id);

  /// Accepts an invitation by its opaque token. Returns the Titipan so the
  /// caller can navigate straight to it.
  Future<Titipan> acceptInvite(String token);

  Future<String> ensureInviteLink(Titipan titipan);

  Future<void> markRead(String titipanId);

  Future<void> refresh();
}
