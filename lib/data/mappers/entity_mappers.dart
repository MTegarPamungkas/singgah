import 'package:singgah/core/utils/json_x.dart';
import 'package:singgah/domain/entities/app_user.dart';
import 'package:singgah/domain/entities/singgah_event.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/entities/titipan.dart';

Titik titikFromRow(Map<String, dynamic> row) => Titik(
  id: stringOr(row['id']),
  ownerId: stringOr(row['owner_id']),
  name: stringOr(row['name']),
  address: stringOr(row['address']),
  latitude: doubleOr(row['latitude']),
  longitude: doubleOr(row['longitude']),
  radiusMeters: intOr(row['radius_meters'], 150).clamp(100, 2000),
  iconKey: stringOr(row['icon_key'], 'pin'),
  colorHex: stringOr(row['color_hex'], '#C94F0E'),
  createdAt: dateOrNull(row['created_at']),
  updatedAt: dateOrNull(row['updated_at']),
  deletedAt: dateOrNull(row['deleted_at']),
);

Map<String, dynamic> titikToRow(Titik place) => {
  'id': place.id,
  'owner_id': place.ownerId,
  'name': place.name,
  'address': place.address,
  'latitude': place.latitude,
  'longitude': place.longitude,
  'radius_meters': place.radiusMeters,
  'icon_key': place.iconKey,
  'color_hex': place.colorHex,
  'created_at': isoOrNull(place.createdAt),
  'updated_at': isoOrNull(place.updatedAt),
  'deleted_at': isoOrNull(place.deletedAt),
};

SinggahMission missionFromRow(Map<String, dynamic> row) {
  final trigger = row['trigger']?.toString() == 'leave'
      ? MissionTrigger.leave
      : MissionTrigger.arrive;
  return SinggahMission(
    id: stringOr(row['id']),
    ownerId: stringOr(row['owner_id']),
    placeId: stringOr(row['place_id']),
    title: stringOr(row['title']),
    note: stringOr(row['note']),
    trigger: trigger,
    repeatDays: intSet(row['repeat_days']),
    windowStartMinutes: intOr(row['window_start_minutes']),
    windowEndMinutes: intOr(row['window_end_minutes'], 24 * 60 - 1),
    isActive: boolOr(row['is_active'], true),
    lastTriggeredAt: dateOrNull(row['last_triggered_at']),
    createdAt: dateOrNull(row['created_at']),
    updatedAt: dateOrNull(row['updated_at']),
    deletedAt: dateOrNull(row['deleted_at']),
  );
}

Map<String, dynamic> missionToRow(SinggahMission mission) => {
  'id': mission.id,
  'owner_id': mission.ownerId,
  'place_id': mission.placeId,
  'title': mission.title,
  'note': mission.note,
  'trigger': mission.trigger.name,
  'repeat_days': (mission.repeatDays.toList()..sort()),
  'window_start_minutes': mission.windowStartMinutes,
  'window_end_minutes': mission.windowEndMinutes,
  'is_active': mission.isActive,
  'last_triggered_at': isoOrNull(mission.lastTriggeredAt),
  'created_at': isoOrNull(mission.createdAt),
  'updated_at': isoOrNull(mission.updatedAt),
  'deleted_at': isoOrNull(mission.deletedAt),
};

Titipan titipanFromRow(Map<String, dynamic> row) {
  final trigger = row['trigger']?.toString() == 'leave'
      ? MissionTrigger.leave
      : MissionTrigger.arrive;
  return Titipan(
    id: stringOr(row['id']),
    senderId: stringOr(row['sender_id']),
    senderName: stringOr(row['sender_name']),
    placeId: stringOrNull(row['place_id']),
    placeName: stringOr(row['place_name']),
    latitude: doubleOr(row['latitude']),
    longitude: doubleOr(row['longitude']),
    radiusMeters: intOr(row['radius_meters'], 150).clamp(100, 2000),
    title: stringOr(row['title']),
    body: stringOr(row['body']),
    trigger: trigger,
    inviteToken: stringOr(row['invite_token']),
    recipientHint: stringOr(row['recipient_hint']),
    createdAt: dateOrNull(row['created_at']),
    updatedAt: dateOrNull(row['updated_at']),
    deletedAt: dateOrNull(row['deleted_at']),
  );
}

Map<String, dynamic> titipanToRow(Titipan titipan) => {
  'id': titipan.id,
  'sender_id': titipan.senderId,
  'sender_name': titipan.senderName,
  'place_id': titipan.placeId,
  'place_name': titipan.placeName,
  'latitude': titipan.latitude,
  'longitude': titipan.longitude,
  'radius_meters': titipan.radiusMeters,
  'title': titipan.title,
  'body': titipan.body,
  'trigger': titipan.trigger.name,
  'invite_token': titipan.inviteToken,
  'recipient_hint': titipan.recipientHint,
  'created_at': isoOrNull(titipan.createdAt),
  'updated_at': isoOrNull(titipan.updatedAt),
  'deleted_at': isoOrNull(titipan.deletedAt),
};

TitipanRecipient recipientFromRow(Map<String, dynamic> row) => TitipanRecipient(
  id: stringOr(row['id']),
  titipanId: stringOr(row['titipan_id']),
  userId: stringOrNull(row['user_id']),
  invitedEmail: stringOrNull(row['invited_email']),
  acceptedAt: dateOrNull(row['accepted_at']),
  readAt: dateOrNull(row['read_at']),
  createdAt: dateOrNull(row['created_at']),
  updatedAt: dateOrNull(row['updated_at']),
);

Map<String, dynamic> recipientToRow(TitipanRecipient recipient) => {
  'id': recipient.id,
  'titipan_id': recipient.titipanId,
  'user_id': recipient.userId,
  'invited_email': recipient.invitedEmail,
  'accepted_at': isoOrNull(recipient.acceptedAt),
  'read_at': isoOrNull(recipient.readAt),
  'created_at': isoOrNull(recipient.createdAt),
  'updated_at': isoOrNull(recipient.updatedAt),
};

SinggahEvent eventFromRow(Map<String, dynamic> row) {
  final trigger = row['trigger']?.toString() == 'leave'
      ? MissionTrigger.leave
      : MissionTrigger.arrive;
  final source = row['source']?.toString() == 'manual'
      ? SinggahEventSource.manual
      : SinggahEventSource.geofence;
  return SinggahEvent(
    id: stringOr(row['id']),
    ownerId: stringOr(row['owner_id']),
    placeId: stringOrNull(row['place_id']),
    placeName: stringOr(row['place_name']),
    missionId: stringOrNull(row['mission_id']),
    titipanId: stringOrNull(row['titipan_id']),
    trigger: trigger,
    occurredAt: dateOrNull(row['occurred_at']) ?? DateTime.now(),
    source: source,
    acknowledged: boolOr(row['acknowledged']),
  );
}

Map<String, dynamic> eventToRow(SinggahEvent event) => {
  'id': event.id,
  'owner_id': event.ownerId,
  'place_id': event.placeId,
  'place_name': event.placeName,
  'mission_id': event.missionId,
  'titipan_id': event.titipanId,
  'trigger': event.trigger.name,
  'occurred_at': isoOrNull(event.occurredAt),
  'source': event.source.name,
  'acknowledged': event.acknowledged,
};

Map<String, dynamic> profileToRow(AppUser user) => {
  'id': user.id,
  'display_name': user.displayName,
  'avatar_url': user.avatarUrl,
  'updated_at': DateTime.now().toUtc().toIso8601String(),
};
