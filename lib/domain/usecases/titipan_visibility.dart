import 'package:singgah/domain/entities/titipan.dart';

/// Client-side mirror of the RLS rules. The database remains authoritative;
/// these helpers keep local caches honest and make the rules testable.
abstract final class TitipanVisibility {
  static bool canRead({
    required Titipan titipan,
    required String userId,
    required List<TitipanRecipient> recipients,
  }) {
    if (titipan.isDeleted) return false;
    if (titipan.senderId == userId) return true;
    return recipients.any(
      (recipient) =>
          recipient.titipanId == titipan.id &&
          recipient.userId == userId &&
          recipient.acceptedAt != null,
    );
  }

  static bool canManage({required Titipan titipan, required String userId}) =>
      !titipan.isDeleted && titipan.senderId == userId;

  static bool isAccepted({
    required String titipanId,
    required String userId,
    required List<TitipanRecipient> recipients,
  }) {
    return recipients.any(
      (recipient) =>
          recipient.titipanId == titipanId &&
          recipient.userId == userId &&
          recipient.acceptedAt != null,
    );
  }

  static List<Titipan> inbox({
    required List<Titipan> titipans,
    required List<TitipanRecipient> recipients,
    required String userId,
  }) {
    return titipans
        .where(
          (titipan) =>
              titipan.senderId != userId &&
              canRead(titipan: titipan, userId: userId, recipients: recipients),
        )
        .toList(growable: false);
  }

  static List<Titipan> sent({
    required List<Titipan> titipans,
    required String userId,
  }) {
    return titipans
        .where((titipan) => canManage(titipan: titipan, userId: userId))
        .toList(growable: false);
  }

  static Set<String> acceptedIds({
    required List<TitipanRecipient> recipients,
    required String userId,
  }) {
    return recipients
        .where(
          (recipient) =>
              recipient.userId == userId && recipient.acceptedAt != null,
        )
        .map((recipient) => recipient.titipanId)
        .toSet();
  }
}
