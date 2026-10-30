import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/core/utils/stream_combine.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';

enum PlacesFailure { load, delete }

class PlacesState extends Equatable {
  const PlacesState({
    this.loading = true,
    this.places = const [],
    this.missionCounts = const {},
    this.deleting = false,
    this.failure,
  });

  final bool loading;
  final List<Titik> places;
  final Map<String, int> missionCounts;
  final bool deleting;
  final PlacesFailure? failure;

  int get totalMissions =>
      missionCounts.values.fold(0, (sum, value) => sum + value);

  PlacesState copyWith({
    bool? loading,
    List<Titik>? places,
    Map<String, int>? missionCounts,
    bool? deleting,
    PlacesFailure? failure,
    bool clearFailure = false,
  }) {
    return PlacesState(
      loading: loading ?? this.loading,
      places: places ?? this.places,
      missionCounts: missionCounts ?? this.missionCounts,
      deleting: deleting ?? this.deleting,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    places,
    missionCounts,
    deleting,
    failure,
  ];
}

sealed class PlacesEvent {
  const PlacesEvent();
}

final class PlacesStarted extends PlacesEvent {
  const PlacesStarted();
}

final class PlacesDataReceived extends PlacesEvent {
  const PlacesDataReceived(this.places, this.missions);
  final List<Titik> places;
  final List<SinggahMission> missions;
}

final class PlacesLoadFailed extends PlacesEvent {
  const PlacesLoadFailed();
}

final class PlaceDeleteRequested extends PlacesEvent {
  const PlaceDeleteRequested(this.id, this.completer);
  final String id;
  final Completer<bool> completer;
}

final class PlacesFailureCleared extends PlacesEvent {
  const PlacesFailureCleared();
}

class PlacesBloc extends Bloc<PlacesEvent, PlacesState> {
  PlacesBloc(this._watchPlaces, this._watchMissions, this._delete)
    : super(const PlacesState()) {
    on<PlacesStarted>(_onStarted);
    on<PlacesDataReceived>(_onData);
    on<PlacesLoadFailed>(
      (event, emit) =>
          emit(state.copyWith(loading: false, failure: PlacesFailure.load)),
    );
    on<PlaceDeleteRequested>(_onDelete);
    on<PlacesFailureCleared>(
      (event, emit) => emit(state.copyWith(clearFailure: true)),
    );
    add(const PlacesStarted());
  }

  final WatchPlaces _watchPlaces;
  final WatchMissions _watchMissions;
  final DeletePlace _delete;

  StreamSubscription<(List<Titik>, List<SinggahMission>)>? _subscription;

  Future<void> _onStarted(
    PlacesStarted event,
    Emitter<PlacesState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription =
        combineLatest2(
          _watchPlaces(),
          _watchMissions(),
          (List<Titik> places, List<SinggahMission> missions) =>
              (places, missions),
        ).listen(
          (value) => add(PlacesDataReceived(value.$1, value.$2)),
          onError: (_) => add(const PlacesLoadFailed()),
        );
  }

  void _onData(PlacesDataReceived event, Emitter<PlacesState> emit) {
    final counts = <String, int>{};
    for (final mission in event.missions) {
      if (mission.isDeleted) continue;
      counts[mission.placeId] = (counts[mission.placeId] ?? 0) + 1;
    }
    emit(
      state.copyWith(
        places: event.places,
        missionCounts: counts,
        loading: false,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onDelete(
    PlaceDeleteRequested event,
    Emitter<PlacesState> emit,
  ) async {
    if (state.deleting) {
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(event.id);
      emit(state.copyWith(deleting: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: PlacesFailure.delete));
      event.completer.complete(false);
    }
  }

  Future<bool> deletePlace(String id) async {
    final completer = Completer<bool>();
    add(PlaceDeleteRequested(id, completer));
    return completer.future;
  }

  void clearFailure() => add(const PlacesFailureCleared());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
