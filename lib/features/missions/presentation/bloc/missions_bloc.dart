import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/core/utils/stream_combine.dart';
import 'package:singgah/domain/entities/geofence_summary.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/services/geofence_manager.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';

enum MissionFilter { all, active, paused }

enum MissionsFailure { load, save, delete }

class MissionsState extends Equatable {
  const MissionsState({
    this.loading = true,
    this.missions = const [],
    this.places = const [],
    this.summary = const GeofenceSummary(),
    this.filter = MissionFilter.all,
    this.saving = false,
    this.deleting = false,
    this.failure,
  });

  final bool loading;
  final List<SinggahMission> missions;
  final List<Titik> places;
  final GeofenceSummary summary;
  final MissionFilter filter;
  final bool saving;
  final bool deleting;
  final MissionsFailure? failure;

  Map<String, Titik> get placesById => {
    for (final place in places) place.id: place,
  };

  List<SinggahMission> get filtered => switch (filter) {
    MissionFilter.all => missions,
    MissionFilter.active =>
      missions.where((mission) => mission.isActive).toList(growable: false),
    MissionFilter.paused =>
      missions.where((mission) => !mission.isActive).toList(growable: false),
  };

  MissionsState copyWith({
    bool? loading,
    List<SinggahMission>? missions,
    List<Titik>? places,
    GeofenceSummary? summary,
    MissionFilter? filter,
    bool? saving,
    bool? deleting,
    MissionsFailure? failure,
    bool clearFailure = false,
  }) {
    return MissionsState(
      loading: loading ?? this.loading,
      missions: missions ?? this.missions,
      places: places ?? this.places,
      summary: summary ?? this.summary,
      filter: filter ?? this.filter,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    missions,
    places,
    summary,
    filter,
    saving,
    deleting,
    failure,
  ];
}

sealed class MissionsEvent {
  const MissionsEvent();
}

final class MissionsStarted extends MissionsEvent {
  const MissionsStarted();
}

final class MissionsDataReceived extends MissionsEvent {
  const MissionsDataReceived(this.missions, this.places, this.summary);
  final List<SinggahMission> missions;
  final List<Titik> places;
  final GeofenceSummary summary;
}

final class MissionsLoadFailed extends MissionsEvent {
  const MissionsLoadFailed();
}

final class MissionsFilterChanged extends MissionsEvent {
  const MissionsFilterChanged(this.filter);
  final MissionFilter filter;
}

final class MissionToggleRequested extends MissionsEvent {
  const MissionToggleRequested(this.mission);
  final SinggahMission mission;
}

final class MissionDeleteRequested extends MissionsEvent {
  const MissionDeleteRequested(this.id, this.completer);
  final String id;
  final Completer<bool> completer;
}

final class MissionsFailureCleared extends MissionsEvent {
  const MissionsFailureCleared();
}

class MissionsBloc extends Bloc<MissionsEvent, MissionsState> {
  MissionsBloc(
    this._watch,
    this._watchPlaces,
    this._geofences,
    this._save,
    this._delete,
  ) : super(const MissionsState()) {
    on<MissionsStarted>(_onStarted);
    on<MissionsDataReceived>(_onData);
    on<MissionsLoadFailed>(
      (event, emit) =>
          emit(state.copyWith(loading: false, failure: MissionsFailure.load)),
    );
    on<MissionsFilterChanged>(
      (event, emit) => emit(state.copyWith(filter: event.filter)),
    );
    on<MissionToggleRequested>(_onToggle);
    on<MissionDeleteRequested>(_onDelete);
    on<MissionsFailureCleared>(
      (event, emit) => emit(state.copyWith(clearFailure: true)),
    );
    add(const MissionsStarted());
  }

  final WatchMissions _watch;
  final WatchPlaces _watchPlaces;
  final GeofenceManager _geofences;
  final SaveMission _save;
  final DeleteMission _delete;

  StreamSubscription<MissionsSnapshot>? _subscription;
  StreamSubscription<GeofenceSummary>? _summarySubscription;

  Future<void> _onStarted(
    MissionsStarted event,
    Emitter<MissionsState> emit,
  ) async {
    await _subscription?.cancel();
    await _summarySubscription?.cancel();
    _subscription =
        combineLatest3(
          _watch(),
          _watchPlaces(),
          _geofences.summaries,
          (
            List<SinggahMission> missions,
            List<Titik> places,
            GeofenceSummary summary,
          ) => MissionsSnapshot(missions, places, summary),
        ).listen(
          (snapshot) => add(
            MissionsDataReceived(
              snapshot.missions,
              snapshot.places,
              snapshot.summary,
            ),
          ),
          onError: (_) => add(const MissionsLoadFailed()),
        );
    _summarySubscription = _geofences.summaries.listen(
      (summary) =>
          add(MissionsDataReceived(state.missions, state.places, summary)),
    );
  }

  void _onData(MissionsDataReceived event, Emitter<MissionsState> emit) {
    emit(
      state.copyWith(
        missions: event.missions,
        places: event.places,
        summary: event.summary,
        loading: false,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onToggle(
    MissionToggleRequested event,
    Emitter<MissionsState> emit,
  ) async {
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      await _save(event.mission.copyWith(isActive: !event.mission.isActive));
      emit(state.copyWith(saving: false));
    } catch (_) {
      emit(state.copyWith(saving: false, failure: MissionsFailure.save));
    }
  }

  Future<void> _onDelete(
    MissionDeleteRequested event,
    Emitter<MissionsState> emit,
  ) async {
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(event.id);
      emit(state.copyWith(deleting: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: MissionsFailure.delete));
      event.completer.complete(false);
    }
  }

  void setFilter(MissionFilter filter) => add(MissionsFilterChanged(filter));
  void toggle(SinggahMission mission) => add(MissionToggleRequested(mission));

  Future<bool> deleteMission(String id) async {
    final completer = Completer<bool>();
    add(MissionDeleteRequested(id, completer));
    return completer.future;
  }

  void clearFailure() => add(const MissionsFailureCleared());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _summarySubscription?.cancel();
    return super.close();
  }
}

class MissionsSnapshot {
  const MissionsSnapshot(this.missions, this.places, this.summary);
  final List<SinggahMission> missions;
  final List<Titik> places;
  final GeofenceSummary summary;
}
