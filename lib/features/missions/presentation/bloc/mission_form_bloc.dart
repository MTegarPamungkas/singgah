import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';

class MissionSeed {
  const MissionSeed({
    this.title = '',
    this.note = '',
    this.trigger = MissionTrigger.arrive,
    this.repeatDays = const {},
    this.windowStartMinutes = 0,
    this.windowEndMinutes = 24 * 60 - 1,
    this.placeId = '',
    this.placeName = '',
    this.isActive = true,
  });

  final String title;
  final String note;
  final MissionTrigger trigger;
  final Set<int> repeatDays;
  final int windowStartMinutes;
  final int windowEndMinutes;
  final String placeId;
  final String placeName;
  final bool isActive;
}

class MissionFormArgs {
  const MissionFormArgs({this.missionId, this.seed});

  final String? missionId;
  final MissionSeed? seed;
}

enum MissionFormFailure {
  load,
  titleRequired,
  placeRequired,
  windowInvalid,
  save,
  delete,
}

class MissionFormState extends Equatable {
  const MissionFormState({
    this.loading = true,
    this.saving = false,
    this.deleting = false,
    this.editing = false,
    this.title = '',
    this.note = '',
    this.trigger = MissionTrigger.arrive,
    this.repeatDays = const {},
    this.windowStartMinutes = 0,
    this.windowEndMinutes = 24 * 60 - 1,
    this.placeId = '',
    this.placeName = '',
    this.isActive = true,
    this.places = const [],
    this.saved = false,
    this.deleted = false,
    this.failure,
  });

  final bool loading;
  final bool saving;
  final bool deleting;
  final bool editing;
  final String title;
  final String note;
  final MissionTrigger trigger;
  final Set<int> repeatDays;
  final int windowStartMinutes;
  final int windowEndMinutes;
  final String placeId;
  final String placeName;
  final bool isActive;
  final List<Titik> places;
  final bool saved;
  final bool deleted;
  final MissionFormFailure? failure;

  bool get everyDay => repeatDays.isEmpty || repeatDays.length == 7;

  bool get canSave =>
      title.trim().isNotEmpty && placeId.isNotEmpty && !saving && !deleting;

  MissionFormState copyWith({
    bool? loading,
    bool? saving,
    bool? deleting,
    bool? editing,
    String? title,
    String? note,
    MissionTrigger? trigger,
    Set<int>? repeatDays,
    int? windowStartMinutes,
    int? windowEndMinutes,
    String? placeId,
    String? placeName,
    bool? isActive,
    List<Titik>? places,
    bool? saved,
    bool? deleted,
    MissionFormFailure? failure,
    bool clearFailure = false,
  }) {
    return MissionFormState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      editing: editing ?? this.editing,
      title: title ?? this.title,
      note: note ?? this.note,
      trigger: trigger ?? this.trigger,
      repeatDays: repeatDays ?? this.repeatDays,
      windowStartMinutes: windowStartMinutes ?? this.windowStartMinutes,
      windowEndMinutes: windowEndMinutes ?? this.windowEndMinutes,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      isActive: isActive ?? this.isActive,
      places: places ?? this.places,
      saved: saved ?? this.saved,
      deleted: deleted ?? this.deleted,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    saving,
    deleting,
    editing,
    title,
    note,
    trigger,
    repeatDays,
    windowStartMinutes,
    windowEndMinutes,
    placeId,
    placeName,
    isActive,
    places,
    saved,
    deleted,
    failure,
  ];
}

sealed class MissionFormEvent {
  const MissionFormEvent();
}

final class MissionFormStarted extends MissionFormEvent {
  const MissionFormStarted();
}

final class MissionFormTitleChanged extends MissionFormEvent {
  const MissionFormTitleChanged(this.value);
  final String value;
}

final class MissionFormNoteChanged extends MissionFormEvent {
  const MissionFormNoteChanged(this.value);
  final String value;
}

final class MissionFormTriggerChanged extends MissionFormEvent {
  const MissionFormTriggerChanged(this.value);
  final MissionTrigger value;
}

final class MissionFormDayToggled extends MissionFormEvent {
  const MissionFormDayToggled(this.weekday);
  final int weekday;
}

final class MissionFormEveryDaySelected extends MissionFormEvent {
  const MissionFormEveryDaySelected();
}

final class MissionFormRepeatPresetSelected extends MissionFormEvent {
  const MissionFormRepeatPresetSelected(this.days);
  final Set<int> days;
}

final class MissionFormWindowChanged extends MissionFormEvent {
  const MissionFormWindowChanged({required this.start, required this.end});
  final int start;
  final int end;
}

final class MissionFormPlaceChanged extends MissionFormEvent {
  const MissionFormPlaceChanged(this.id, this.name);
  final String id;
  final String name;
}

final class MissionFormActiveChanged extends MissionFormEvent {
  const MissionFormActiveChanged(this.value);
  final bool value;
}

final class MissionFormSaveRequested extends MissionFormEvent {
  const MissionFormSaveRequested();
}

final class MissionFormDeleteRequested extends MissionFormEvent {
  const MissionFormDeleteRequested();
}

final class MissionFormFailureCleared extends MissionFormEvent {
  const MissionFormFailureCleared();
}

class MissionFormBloc extends Bloc<MissionFormEvent, MissionFormState> {
  MissionFormBloc({
    required GetMission getMission,
    required GetPlaces getPlaces,
    required SaveMission saveMission,
    required DeleteMission deleteMission,
    required AuthRepository auth,
    required this.args,
    Uuid? uuid,
  }) : _getMission = getMission,
       _getPlaces = getPlaces,
       _saveMission = saveMission,
       _deleteMission = deleteMission,
       _auth = auth,
       _uuid = uuid ?? const Uuid(),
       super(const MissionFormState()) {
    on<MissionFormStarted>(_onStarted);
    on<MissionFormTitleChanged>(
      (event, emit) =>
          emit(state.copyWith(title: event.value, clearFailure: true)),
    );
    on<MissionFormNoteChanged>(
      (event, emit) => emit(state.copyWith(note: event.value)),
    );
    on<MissionFormTriggerChanged>(
      (event, emit) => emit(state.copyWith(trigger: event.value)),
    );
    on<MissionFormDayToggled>(_onDayToggled);
    on<MissionFormEveryDaySelected>(
      (event, emit) => emit(state.copyWith(repeatDays: const {})),
    );
    on<MissionFormRepeatPresetSelected>(
      (event, emit) => emit(state.copyWith(repeatDays: event.days)),
    );
    on<MissionFormWindowChanged>(
      (event, emit) => emit(
        state.copyWith(
          windowStartMinutes: event.start.clamp(0, 24 * 60 - 1),
          windowEndMinutes: event.end.clamp(0, 24 * 60 - 1),
          clearFailure: true,
        ),
      ),
    );
    on<MissionFormPlaceChanged>(
      (event, emit) => emit(
        state.copyWith(
          placeId: event.id,
          placeName: event.name,
          clearFailure: true,
        ),
      ),
    );
    on<MissionFormActiveChanged>(
      (event, emit) => emit(state.copyWith(isActive: event.value)),
    );
    on<MissionFormSaveRequested>(_onSave);
    on<MissionFormDeleteRequested>(_onDelete);
    on<MissionFormFailureCleared>(
      (event, emit) => emit(state.copyWith(clearFailure: true)),
    );
    add(const MissionFormStarted());
  }

  final GetMission _getMission;
  final GetPlaces _getPlaces;
  final SaveMission _saveMission;
  final DeleteMission _deleteMission;
  final AuthRepository _auth;
  final Uuid _uuid;
  final MissionFormArgs args;

  Future<void> _onStarted(
    MissionFormStarted event,
    Emitter<MissionFormState> emit,
  ) async {
    final places = await _getPlaces();
    final seed = args.seed;
    if (args.missionId != null) {
      final mission = await _getMission(args.missionId!);
      if (mission == null) {
        emit(
          state.copyWith(
            loading: false,
            places: places,
            failure: MissionFormFailure.load,
          ),
        );
        return;
      }
      emit(
        MissionFormState(
          loading: false,
          editing: true,
          title: mission.title,
          note: mission.note,
          trigger: mission.trigger,
          repeatDays: mission.repeatDays,
          windowStartMinutes: mission.windowStartMinutes,
          windowEndMinutes: mission.windowEndMinutes,
          placeId: mission.placeId,
          placeName: _placeName(places, mission.placeId),
          isActive: mission.isActive,
          places: places,
        ),
      );
      return;
    }
    emit(
      MissionFormState(
        loading: false,
        editing: false,
        title: seed?.title ?? '',
        note: seed?.note ?? '',
        trigger: seed?.trigger ?? MissionTrigger.arrive,
        repeatDays: seed?.repeatDays ?? const {},
        windowStartMinutes: seed?.windowStartMinutes ?? 0,
        windowEndMinutes: seed?.windowEndMinutes ?? 24 * 60 - 1,
        placeId: seed?.placeId ?? '',
        placeName: seed?.placeName ?? '',
        isActive: seed?.isActive ?? true,
        places: places,
      ),
    );
  }

  void _onDayToggled(
    MissionFormDayToggled event,
    Emitter<MissionFormState> emit,
  ) {
    final next = Set<int>.from(state.repeatDays);
    if (next.contains(event.weekday)) {
      next.remove(event.weekday);
    } else {
      next.add(event.weekday);
    }
    emit(state.copyWith(repeatDays: next));
  }

  Future<void> _onSave(
    MissionFormSaveRequested event,
    Emitter<MissionFormState> emit,
  ) async {
    if (state.title.trim().isEmpty) {
      emit(state.copyWith(failure: MissionFormFailure.titleRequired));
      return;
    }
    if (state.placeId.isEmpty) {
      emit(state.copyWith(failure: MissionFormFailure.placeRequired));
      return;
    }
    if (state.windowStartMinutes == state.windowEndMinutes) {
      emit(state.copyWith(failure: MissionFormFailure.windowInvalid));
      return;
    }
    emit(state.copyWith(saving: true, clearFailure: true, saved: false));
    try {
      final now = DateTime.now();
      final mission = SinggahMission(
        id: args.missionId ?? _uuid.v4(),
        ownerId: _auth.currentUser?.id ?? AppConfig.demoUserId,
        placeId: state.placeId,
        title: state.title.trim(),
        note: state.note.trim(),
        trigger: state.trigger,
        repeatDays: state.repeatDays,
        windowStartMinutes: state.windowStartMinutes,
        windowEndMinutes: state.windowEndMinutes,
        isActive: state.isActive,
        createdAt: now,
        updatedAt: now,
      );
      await _saveMission(mission);
      emit(state.copyWith(saving: false, saved: true));
    } catch (_) {
      emit(state.copyWith(saving: false, failure: MissionFormFailure.save));
    }
  }

  Future<void> _onDelete(
    MissionFormDeleteRequested event,
    Emitter<MissionFormState> emit,
  ) async {
    final id = args.missionId;
    if (id == null) return;
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _deleteMission(id);
      emit(state.copyWith(deleting: false, deleted: true));
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: MissionFormFailure.delete));
    }
  }

  void setTitle(String value) => add(MissionFormTitleChanged(value));
  void setNote(String value) => add(MissionFormNoteChanged(value));
  void setTrigger(MissionTrigger value) =>
      add(MissionFormTriggerChanged(value));
  void toggleDay(int weekday) => add(MissionFormDayToggled(weekday));
  void selectEveryDay() => add(const MissionFormEveryDaySelected());
  void selectWeekdays() =>
      add(const MissionFormRepeatPresetSelected({1, 2, 3, 4, 5}));
  void selectWeekends() => add(const MissionFormRepeatPresetSelected({6, 7}));
  void setWindow(int start, int end) =>
      add(MissionFormWindowChanged(start: start, end: end));
  void setPlace(String id, String name) =>
      add(MissionFormPlaceChanged(id, name));
  void setActive(bool value) => add(MissionFormActiveChanged(value));
  void save() => add(const MissionFormSaveRequested());
  void delete() => add(const MissionFormDeleteRequested());
  void clearFailure() => add(const MissionFormFailureCleared());

  String _placeName(List<Titik> places, String id) {
    for (final place in places) {
      if (place.id == id) return place.name;
    }
    return '';
  }
}
