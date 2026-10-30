import 'package:flutter_test/flutter_test.dart';

import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/usecases/titipan_visibility.dart';

Titipan note(String id, String sender, {bool deleted = false}) => Titipan(
  id: id,
  senderId: sender,
  senderName: 'Sender',
  placeName: 'Rumah',
  latitude: -6.2,
  longitude: 106.8,
  title: 'Judul $id',
  body: 'Isi',
  trigger: MissionTrigger.arrive,
  deletedAt: deleted ? DateTime(2026, 10, 20) : null,
);

TitipanRecipient recipient(
  String noteId,
  String userId, {
  bool accepted = true,
}) => TitipanRecipient(
  id: 'r-$noteId-$userId',
  titipanId: noteId,
  userId: userId,
  acceptedAt: accepted ? DateTime(2026, 10, 21) : null,
);

void main() {
  test('owner can manage their own live note', () {
    final titipan = note('t1', 'me');
    expect(
      TitipanVisibility.canRead(
        titipan: titipan,
        userId: 'me',
        recipients: const [],
      ),
      isTrue,
    );
    expect(TitipanVisibility.canManage(titipan: titipan, userId: 'me'), isTrue);
    expect(
      TitipanVisibility.canManage(titipan: titipan, userId: 'other'),
      isFalse,
    );
  });

  test('recipients only see notes they accepted', () {
    final titipan = note('t1', 'friend');
    expect(
      TitipanVisibility.canRead(
        titipan: titipan,
        userId: 'me',
        recipients: [recipient('t1', 'me', accepted: false)],
      ),
      isFalse,
    );
    expect(
      TitipanVisibility.canRead(
        titipan: titipan,
        userId: 'me',
        recipients: [recipient('t1', 'me')],
      ),
      isTrue,
    );
  });

  test('deleted notes disappear for everyone', () {
    final titipan = note('t1', 'friend', deleted: true);
    expect(
      TitipanVisibility.canRead(
        titipan: titipan,
        userId: 'me',
        recipients: [recipient('t1', 'me')],
      ),
      isFalse,
    );
  });

  test('inbox excludes sent notes and pending invites', () {
    final notes = [
      note('mine', 'me'),
      note('accepted', 'friend'),
      note('pending', 'friend'),
    ];
    final feed = [
      recipient('accepted', 'me'),
      recipient('pending', 'me', accepted: false),
      recipient('mine', 'me'),
    ];
    final inbox = TitipanVisibility.inbox(
      titipans: notes,
      recipients: feed,
      userId: 'me',
    );
    expect(inbox.map((item) => item.id), ['accepted']);

    final sent = TitipanVisibility.sent(titipans: notes, userId: 'me');
    expect(sent.map((item) => item.id), ['mine']);
  });

  test('acceptedIds only includes accepted recipients for the user', () {
    final ids = TitipanVisibility.acceptedIds(
      recipients: [
        recipient('a', 'me'),
        recipient('b', 'me', accepted: false),
        recipient('c', 'someone'),
      ],
      userId: 'me',
    );
    expect(ids, {'a'});
  });
}
