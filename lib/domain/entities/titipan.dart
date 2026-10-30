import 'package:equatable/equatable.dart';

import 'singgah_mission.dart';

class Titipan extends Equatable {
  const Titipan({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.body,
    this.placeId,
    this.radiusMeters = 150,
    this.trigger = MissionTrigger.arrive,
    this.inviteToken = '',
    this.recipientHint = '',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? placeId;
  final String placeName;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String title;
  final String body;
  final MissionTrigger trigger;
  final String inviteToken;
  final String recipientHint;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  Titipan copyWith({
    String? title,
    String? body,
    String? placeName,
    String? placeId,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    MissionTrigger? trigger,
    String? inviteToken,
    String? recipientHint,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Titipan(
      id: id,
      senderId: senderId,
      senderName: senderName,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: (radiusMeters ?? this.radiusMeters).clamp(100, 2000),
      title: title ?? this.title,
      body: body ?? this.body,
      trigger: trigger ?? this.trigger,
      inviteToken: inviteToken ?? this.inviteToken,
      recipientHint: recipientHint ?? this.recipientHint,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    senderName,
    placeId,
    placeName,
    latitude,
    longitude,
    radiusMeters,
    title,
    body,
    trigger,
    inviteToken,
    recipientHint,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class TitipanRecipient extends Equatable {
  const TitipanRecipient({
    required this.id,
    required this.titipanId,
    this.userId,
    this.invitedEmail,
    this.acceptedAt,
    this.readAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String titipanId;
  final String? userId;
  final String? invitedEmail;
  final DateTime? acceptedAt;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get accepted => acceptedAt != null;

  TitipanRecipient copyWith({
    String? userId,
    String? invitedEmail,
    DateTime? acceptedAt,
    DateTime? readAt,
    DateTime? updatedAt,
  }) {
    return TitipanRecipient(
      id: id,
      titipanId: titipanId,
      userId: userId ?? this.userId,
      invitedEmail: invitedEmail ?? this.invitedEmail,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    titipanId,
    userId,
    invitedEmail,
    acceptedAt,
    readAt,
    createdAt,
    updatedAt,
  ];
}
