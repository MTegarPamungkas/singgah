import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';
import 'package:singgah/domain/usecases/titipan_usecases.dart';

class TitipanFormSeed {
  const TitipanFormSeed({
    this.placeId = '',
    this.placeName = '',
    this.latitude,
    this.longitude,
    this.radiusMeters = 150,
    this.title = '',
    this.body = '',
    this.trigger = MissionTrigger.arrive,
  });

  final String placeId;
  final String placeName;
  final double? latitude;
  final double? longitude;
  final int radiusMeters;
  final String title;
  final String body;
  final MissionTrigger trigger;
}

enum TitipanFormFailure {
  titleRequired,
  bodyRequired,
  placeRequired,
  save,
  link,
  directSend,
}

class TitipanFormState extends Equatable {
  const TitipanFormState({
    this.loading = true,
    this.saving = false,
    this.title = '',
    this.body = '',
    this.trigger = MissionTrigger.arrive,
    this.placeId = '',
    this.placeName = '',
    this.latitude,
    this.longitude,
    this.radiusMeters = 150,
    this.recipientHint = '',
    this.places = const [],
    this.savedId,
    this.inviteLink,
    this.inviteToken = '',
    this.savedAt,
    this.socialSending = false,
    this.socialSent = false,
    this.directCount = 0,
    this.failure,
  });

  final bool loading;
  final bool saving;
  final String title;
  final String body;
  final MissionTrigger trigger;
  final String placeId;
  final String placeName;
  final double? latitude;
  final double? longitude;
  final int radiusMeters;
  final String recipientHint;
  final List<Titik> places;
  final String? savedId;
  final String? inviteLink;
  final String inviteToken;
  final DateTime? savedAt;
  final bool socialSending;
  final bool socialSent;
  final int directCount;
  final TitipanFormFailure? failure;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get canSave =>
      title.trim().isNotEmpty &&
      body.trim().isNotEmpty &&
      placeId.isNotEmpty &&
      hasCoordinates &&
      !saving;

  TitipanFormState copyWith({
    bool? loading,
    bool? saving,
    String? title,
    String? body,
    MissionTrigger? trigger,
    String? placeId,
    String? placeName,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    String? recipientHint,
    List<Titik>? places,
    String? savedId,
    String? inviteLink,
    String? inviteToken,
    DateTime? savedAt,
    bool? socialSending,
    bool? socialSent,
    int? directCount,
    TitipanFormFailure? failure,
    bool clearFailure = false,
  }) {
    return TitipanFormState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      title: title ?? this.title,
      body: body ?? this.body,
      trigger: trigger ?? this.trigger,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      recipientHint: recipientHint ?? this.recipientHint,
      places: places ?? this.places,
      savedId: savedId ?? this.savedId,
      inviteLink: inviteLink ?? this.inviteLink,
      inviteToken: inviteToken ?? this.inviteToken,
      savedAt: savedAt ?? this.savedAt,
      socialSending: socialSending ?? this.socialSending,
      socialSent: socialSent ?? this.socialSent,
      directCount: directCount ?? this.directCount,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    saving,
    title,
    body,
    trigger,
    placeId,
    placeName,
    latitude,
    longitude,
    radiusMeters,
    recipientHint,
    places,
    savedId,
    inviteLink,
    inviteToken,
    savedAt,
    socialSending,
    socialSent,
    directCount,
    failure,
  ];
}

sealed class TitipanFormEvent {
  const TitipanFormEvent();
}

final class TitipanFormStarted extends TitipanFormEvent {
  const TitipanFormStarted();
}

final class TitipanFormTitleChanged extends TitipanFormEvent {
  const TitipanFormTitleChanged(this.value);
  final String value;
}

final class TitipanFormBodyChanged extends TitipanFormEvent {
  const TitipanFormBodyChanged(this.value);
  final String value;
}

final class TitipanFormTriggerChanged extends TitipanFormEvent {
  const TitipanFormTriggerChanged(this.value);
  final MissionTrigger value;
}

final class TitipanFormPlaceChanged extends TitipanFormEvent {
  const TitipanFormPlaceChanged({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 150,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
}

final class TitipanFormRecipientChanged extends TitipanFormEvent {
  const TitipanFormRecipientChanged(this.value);
  final String value;
}

final class TitipanFormSaveRequested extends TitipanFormEvent {
  const TitipanFormSaveRequested();
}

final class TitipanFormLinkRequested extends TitipanFormEvent {
  const TitipanFormLinkRequested();
}

final class TitipanFormFailureCleared extends TitipanFormEvent {
  const TitipanFormFailureCleared();
}

final class TitipanFormDirectSendRequested extends TitipanFormEvent {
  const TitipanFormDirectSendRequested({
    required this.friendIds,
    required this.groupIds,
  });

  final List<String> friendIds;
  final List<String> groupIds;
}

class TitipanFormBloc extends Bloc<TitipanFormEvent, TitipanFormState> {
  TitipanFormBloc({
    required GetPlaces getPlaces,
    required SaveTitipan saveTitipan,
    required EnsureTitipanInviteLink ensureLink,
    required AuthRepository auth,
    required CloudGateway gateway,
    this.seed,
    Uuid? uuid,
  }) : _getPlaces = getPlaces,
       _saveTitipan = saveTitipan,
       _ensureLink = ensureLink,
       _auth = auth,
       _gateway = gateway,
       _uuid = uuid ?? const Uuid(),
       super(const TitipanFormState()) {
    on<TitipanFormStarted>(_onStarted);
    on<TitipanFormTitleChanged>(
      (event, emit) =>
          emit(state.copyWith(title: event.value, clearFailure: true)),
    );
    on<TitipanFormBodyChanged>(
      (event, emit) =>
          emit(state.copyWith(body: event.value, clearFailure: true)),
    );
    on<TitipanFormTriggerChanged>(
      (event, emit) => emit(state.copyWith(trigger: event.value)),
    );
    on<TitipanFormPlaceChanged>(_onPlaceChanged);
    on<TitipanFormRecipientChanged>(
      (event, emit) => emit(state.copyWith(recipientHint: event.value)),
    );
    on<TitipanFormSaveRequested>(_onSave);
    on<TitipanFormLinkRequested>(_onLink);
    on<TitipanFormFailureCleared>(
      (event, emit) => emit(state.copyWith(clearFailure: true)),
    );
    on<TitipanFormDirectSendRequested>(_onDirectSend);
    add(const TitipanFormStarted());
  }

  final GetPlaces _getPlaces;
  final SaveTitipan _saveTitipan;
  final EnsureTitipanInviteLink _ensureLink;
  final AuthRepository _auth;
  final CloudGateway _gateway;
  final Uuid _uuid;
  final TitipanFormSeed? seed;

  Future<void> _onStarted(
    TitipanFormStarted event,
    Emitter<TitipanFormState> emit,
  ) async {
    final places = await _getPlaces();
    emit(
      TitipanFormState(
        loading: false,
        title: seed?.title ?? '',
        body: seed?.body ?? '',
        trigger: seed?.trigger ?? MissionTrigger.arrive,
        placeId: seed?.placeId ?? '',
        placeName: seed?.placeName ?? '',
        latitude: seed?.latitude,
        longitude: seed?.longitude,
        radiusMeters: seed?.radiusMeters ?? 150,
        places: places,
      ),
    );
  }

  void _onPlaceChanged(
    TitipanFormPlaceChanged event,
    Emitter<TitipanFormState> emit,
  ) {
    emit(
      state.copyWith(
        placeId: event.id,
        placeName: event.name,
        latitude: event.latitude,
        longitude: event.longitude,
        radiusMeters: event.radiusMeters,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onSave(
    TitipanFormSaveRequested event,
    Emitter<TitipanFormState> emit,
  ) async {
    if (state.title.trim().isEmpty) {
      emit(state.copyWith(failure: TitipanFormFailure.titleRequired));
      return;
    }
    if (state.body.trim().isEmpty) {
      emit(state.copyWith(failure: TitipanFormFailure.bodyRequired));
      return;
    }
    if (state.placeId.isEmpty || !state.hasCoordinates) {
      emit(state.copyWith(failure: TitipanFormFailure.placeRequired));
      return;
    }
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      final now = DateTime.now();
      final user = _auth.currentUser;
      final titipan = Titipan(
        id: _uuid.v4(),
        senderId: user?.id ?? AppConfig.demoUserId,
        senderName: user?.displayName ?? AppConfig.demoName,
        placeId: state.placeId,
        placeName: state.placeName.trim(),
        latitude: state.latitude!,
        longitude: state.longitude!,
        radiusMeters: state.radiusMeters.clamp(100, 2000),
        title: state.title.trim(),
        body: state.body.trim(),
        trigger: state.trigger,
        inviteToken: _uuid.v4(),
        recipientHint: state.recipientHint.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await _saveTitipan(titipan);
      final link = await _ensureLink(titipan);
      emit(
        state.copyWith(
          saving: false,
          savedId: titipan.id,
          inviteLink: link,
          inviteToken: titipan.inviteToken,
          savedAt: now,
        ),
      );
    } catch (_) {
      emit(state.copyWith(saving: false, failure: TitipanFormFailure.save));
    }
  }

  Future<void> _onLink(
    TitipanFormLinkRequested event,
    Emitter<TitipanFormState> emit,
  ) async {
    final id = state.savedId;
    if (id == null) return;
    final user = _auth.currentUser;
    final titipan = Titipan(
      id: id,
      senderId: user?.id ?? AppConfig.demoUserId,
      senderName: user?.displayName ?? AppConfig.demoName,
      placeId: state.placeId,
      placeName: state.placeName,
      latitude: state.latitude ?? 0,
      longitude: state.longitude ?? 0,
      title: state.title,
      body: state.body,
      trigger: state.trigger,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      final link = await _ensureLink(titipan);
      emit(state.copyWith(inviteLink: link));
    } catch (_) {
      emit(state.copyWith(failure: TitipanFormFailure.link));
    }
  }

  Future<void> _onDirectSend(
    TitipanFormDirectSendRequested event,
    Emitter<TitipanFormState> emit,
  ) async {
    final id = state.savedId;
    if (id == null || event.friendIds.isEmpty && event.groupIds.isEmpty) {
      return;
    }
    emit(state.copyWith(socialSending: true, clearFailure: true));
    final now = DateTime.now();
    final user = _auth.currentUser;
    try {
      final count = await _gateway.sendTitipanDirect(
        titipan: {
          'id': id,
          'sender_id': user?.id ?? AppConfig.demoUserId,
          'sender_name': user?.displayName ?? AppConfig.demoName,
          'place_id': state.placeId,
          'place_name': state.placeName,
          'latitude': state.latitude ?? 0,
          'longitude': state.longitude ?? 0,
          'radius_meters': state.radiusMeters,
          'title': state.title,
          'body': state.body,
          'trigger': state.trigger.name,
          'invite_token': state.inviteToken,
          'recipient_hint': state.recipientHint,
          'created_at': (state.savedAt ?? now).toUtc().toIso8601String(),
          'updated_at': now.toUtc().toIso8601String(),
        },
        friendIds: event.friendIds,
        groupIds: event.groupIds,
      );
      emit(
        state.copyWith(
          socialSending: false,
          socialSent: true,
          directCount: count,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          socialSending: false,
          failure: TitipanFormFailure.directSend,
        ),
      );
    }
  }

  void setTitle(String value) => add(TitipanFormTitleChanged(value));
  void setBody(String value) => add(TitipanFormBodyChanged(value));
  void setTrigger(MissionTrigger value) =>
      add(TitipanFormTriggerChanged(value));
  void setPlace(Titik place) => add(
    TitipanFormPlaceChanged(
      id: place.id,
      name: place.name,
      latitude: place.latitude,
      longitude: place.longitude,
      radiusMeters: place.radiusMeters,
    ),
  );
  void setRecipient(String value) => add(TitipanFormRecipientChanged(value));
  void save() => add(const TitipanFormSaveRequested());
  void loadLink() => add(const TitipanFormLinkRequested());
  void sendDirect({
    required List<String> friendIds,
    required List<String> groupIds,
  }) => add(
    TitipanFormDirectSendRequested(friendIds: friendIds, groupIds: groupIds),
  );
  void clearFailure() => add(const TitipanFormFailureCleared());
}
