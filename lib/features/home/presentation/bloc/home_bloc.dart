import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/core/utils/stream_combine.dart';
import 'package:singgah/domain/entities/geofence_summary.dart';
import 'package:singgah/domain/entities/singgah_event.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/entities/titipan_feed.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/services/geofence_manager.dart';
import 'package:singgah/domain/usecases/history_usecases.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';
import 'package:singgah/domain/usecases/titipan_usecases.dart';
import 'package:singgah/domain/usecases/titipan_visibility.dart';

class HomeState extends Equatable {
  const HomeState({
    this.loading = true,
    this.missions = const [],
    this.places = const [],
    this.feed = const TitipanFeed(),
    this.events = const [],
    this.summary = const GeofenceSummary(),
    this.userId = '',
    this.failure = false,
  });

  final bool loading;
  final List<SinggahMission> missions;
  final List<Titik> places;
  final TitipanFeed feed;
  final List<SinggahEvent> events;
  final GeofenceSummary summary;
  final String userId;
  final bool failure;

  Map<String, Titik> get placesById => {
    for (final place in places) place.id: place,
  };

  List<SinggahMission> get activeMissions =>
      missions.where((mission) => mission.isActive).toList(growable: false);

  List<SinggahMission> todayMissions(DateTime now) => activeMissions
      .where((mission) => mission.runsOn(now.weekday))
      .toList(growable: false);

  List<Titipan> get inbox => TitipanVisibility.inbox(
    titipans: feed.titipans,
    recipients: feed.recipients,
    userId: userId,
  );

  int get unreadInbox => inbox.where((titipan) {
    final recipients = feed.recipients.where(
      (recipient) =>
          recipient.titipanId == titipan.id && recipient.userId == userId,
    );
    return recipients.every((recipient) => recipient.readAt == null);
  }).length;

  HomeState copyWith({
    bool? loading,
    List<SinggahMission>? missions,
    List<Titik>? places,
    TitipanFeed? feed,
    List<SinggahEvent>? events,
    GeofenceSummary? summary,
    String? userId,
    bool? failure,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      missions: missions ?? this.missions,
      places: places ?? this.places,
      feed: feed ?? this.feed,
      events: events ?? this.events,
      summary: summary ?? this.summary,
      userId: userId ?? this.userId,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    missions,
    places,
    feed,
    events,
    summary,
    userId,
    failure,
  ];
}

sealed class HomeEvent {
  const HomeEvent();
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeDataReceived extends HomeEvent {
  const HomeDataReceived(this.snapshot);
  final HomeSnapshot snapshot;
}

final class HomeLoadFailed extends HomeEvent {
  const HomeLoadFailed();
}

final class HomeSummaryReceived extends HomeEvent {
  const HomeSummaryReceived(this.summary);
  final GeofenceSummary summary;
}

class HomeSnapshot {
  const HomeSnapshot({
    required this.missions,
    required this.places,
    required this.feed,
    required this.events,
    required this.summary,
  });

  final List<SinggahMission> missions;
  final List<Titik> places;
  final TitipanFeed feed;
  final List<SinggahEvent> events;
  final GeofenceSummary summary;
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(
    this._watchMissions,
    this._watchPlaces,
    this._watchFeed,
    this._watchHistory,
    this._geofences,
    AuthRepository auth,
  ) : _userId = auth.currentUser?.id ?? '',
      super(HomeState(userId: auth.currentUser?.id ?? '')) {
    on<HomeStarted>(_onStarted);
    on<HomeDataReceived>(_onData);
    on<HomeLoadFailed>(
      (event, emit) => emit(state.copyWith(loading: false, failure: true)),
    );
    on<HomeSummaryReceived>(
      (event, emit) => emit(state.copyWith(summary: event.summary)),
    );
    add(const HomeStarted());
  }

  final WatchMissions _watchMissions;
  final WatchPlaces _watchPlaces;
  final WatchTitipanFeed _watchFeed;
  final WatchHistory _watchHistory;
  final GeofenceManager _geofences;
  final String _userId;

  StreamSubscription<HomeSnapshot>? _subscription;
  StreamSubscription<GeofenceSummary>? _summarySubscription;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    await _subscription?.cancel();
    await _summarySubscription?.cancel();
    _subscription =
        combineLatest5(
          _watchMissions(),
          _watchPlaces(),
          _watchFeed(),
          _watchHistory(),
          _geofences.summaries,
          (
            List<SinggahMission> missions,
            List<Titik> places,
            TitipanFeed feed,
            List<SinggahEvent> events,
            GeofenceSummary summary,
          ) => HomeSnapshot(
            missions: missions,
            places: places,
            feed: feed,
            events: events,
            summary: summary,
          ),
        ).listen(
          (snapshot) => add(HomeDataReceived(snapshot)),
          onError: (_) => add(const HomeLoadFailed()),
        );
    _summarySubscription = _geofences.summaries.listen(
      (summary) => add(HomeSummaryReceived(summary)),
    );
  }

  void _onData(HomeDataReceived event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        missions: event.snapshot.missions,
        places: event.snapshot.places,
        feed: event.snapshot.feed,
        events: event.snapshot.events,
        summary: event.snapshot.summary,
        userId: _userId,
        loading: false,
        failure: false,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _summarySubscription?.cancel();
    return super.close();
  }
}
