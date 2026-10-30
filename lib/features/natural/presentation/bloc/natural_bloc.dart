import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/domain/entities/natural_draft.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';
import 'package:singgah/domain/usecases/discovery_usecases.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';

enum NaturalFailure { empty, tooLong, unavailable, rateLimited, noPlace, save }

class NaturalState extends Equatable {
  const NaturalState({
    this.loading = true,
    this.text = '',
    this.parsing = false,
    this.saving = false,
    this.draft,
    this.places = const [],
    this.selectedPlace,
    this.suggestion,
    this.saved = false,
    this.failure,
  });

  final bool loading;
  final String text;
  final bool parsing;
  final bool saving;
  final NaturalDraft? draft;
  final List<Titik> places;
  final Titik? selectedPlace;
  final PlaceSuggestion? suggestion;
  final bool saved;
  final NaturalFailure? failure;

  bool get wantsNewPlace => selectedPlace == null && suggestion != null;

  NaturalState copyWith({
    bool? loading,
    String? text,
    bool? parsing,
    bool? saving,
    NaturalDraft? draft,
    bool? clearDraft,
    List<Titik>? places,
    Titik? selectedPlace,
    bool? clearSelectedPlace,
    PlaceSuggestion? suggestion,
    bool? clearSuggestion,
    bool? saved,
    NaturalFailure? failure,
    bool clearFailure = false,
  }) {
    return NaturalState(
      loading: loading ?? this.loading,
      text: text ?? this.text,
      parsing: parsing ?? this.parsing,
      saving: saving ?? this.saving,
      draft: clearDraft == true ? null : (draft ?? this.draft),
      places: places ?? this.places,
      selectedPlace: clearSelectedPlace == true
          ? null
          : (selectedPlace ?? this.selectedPlace),
      suggestion: clearSuggestion == true
          ? null
          : (suggestion ?? this.suggestion),
      saved: saved ?? this.saved,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    text,
    parsing,
    saving,
    draft,
    places,
    selectedPlace,
    suggestion,
    saved,
    failure,
  ];
}

sealed class NaturalEvent {
  const NaturalEvent();
}

final class NaturalStarted extends NaturalEvent {
  const NaturalStarted();
}

final class NaturalTextChanged extends NaturalEvent {
  const NaturalTextChanged(this.text);
  final String text;
}

final class NaturalParseRequested extends NaturalEvent {
  const NaturalParseRequested();
}

final class NaturalDraftTitleChanged extends NaturalEvent {
  const NaturalDraftTitleChanged(this.title);
  final String title;
}

final class NaturalDraftPlaceNameChanged extends NaturalEvent {
  const NaturalDraftPlaceNameChanged(this.name);
  final String name;
}

final class NaturalDraftTriggerChanged extends NaturalEvent {
  const NaturalDraftTriggerChanged(this.trigger);
  final MissionTrigger trigger;
}

final class NaturalDraftRepeatChanged extends NaturalEvent {
  const NaturalDraftRepeatChanged(this.days);
  final Set<int> days;
}

final class NaturalDraftWindowChanged extends NaturalEvent {
  const NaturalDraftWindowChanged({required this.start, required this.end});
  final int start;
  final int end;
}

final class NaturalPlaceSelected extends NaturalEvent {
  const NaturalPlaceSelected(this.place);
  final Titik? place;
}

final class NaturalSuggestionSelected extends NaturalEvent {
  const NaturalSuggestionSelected(this.suggestion);
  final PlaceSuggestion suggestion;
}

final class NaturalSaveRequested extends NaturalEvent {
  const NaturalSaveRequested();
}

final class NaturalResetRequested extends NaturalEvent {
  const NaturalResetRequested();
}

final class NaturalFailureCleared extends NaturalEvent {
  const NaturalFailureCleared();
}

class NaturalBloc extends Bloc<NaturalEvent, NaturalState> {
  NaturalBloc({
    required ParseNaturalReminder parse,
    required WatchPlaces watchPlaces,
    required SavePlace savePlace,
    required SaveMission saveMission,
    required AuthRepository auth,
    Uuid? uuid,
  }) : _parse = parse,
       _watchPlaces = watchPlaces,
       _savePlace = savePlace,
       _saveMission = saveMission,
       _auth = auth,
       _uuid = uuid ?? const Uuid(),
       super(const NaturalState()) {
    on<NaturalStarted>(_onStarted);
    on<NaturalTextChanged>(
      (event, emit) => emit(
        state.copyWith(text: event.text, saved: false, clearFailure: true),
      ),
    );
    on<NaturalParseRequested>(_onParse);
    on<NaturalDraftTitleChanged>(_onTitle);
    on<NaturalDraftPlaceNameChanged>(_onPlaceName);
    on<NaturalDraftTriggerChanged>(
      (event, emit) => emit(
        state.copyWith(
          draft: state.draft?.copyWith(trigger: event.trigger),
          clearFailure: true,
        ),
      ),
    );
    on<NaturalDraftRepeatChanged>(
      (event, emit) => emit(
        state.copyWith(
          draft: state.draft?.copyWith(repeatDays: event.days),
          clearFailure: true,
        ),
      ),
    );
    on<NaturalDraftWindowChanged>(
      (event, emit) => emit(
        state.copyWith(
          draft: state.draft?.copyWith(
            windowStartMinutes: event.start.clamp(0, 24 * 60 - 1),
            windowEndMinutes: event.end.clamp(0, 24 * 60 - 1),
          ),
          clearFailure: true,
        ),
      ),
    );
    on<NaturalPlaceSelected>(_onPlaceSelected);
    on<NaturalSuggestionSelected>(_onSuggestionSelected);
    on<NaturalSaveRequested>(_onSave);
    on<NaturalResetRequested>(
      (event, emit) => emit(
        const NaturalState(loading: false).copyWith(places: state.places),
      ),
    );
    on<NaturalFailureCleared>(
      (event, emit) => emit(state.copyWith(clearFailure: true)),
    );
    on<NaturalPlacesUpdated>(
      (event, emit) => emit(state.copyWith(places: event.places)),
    );
    add(const NaturalStarted());
  }

  final ParseNaturalReminder _parse;
  final WatchPlaces _watchPlaces;
  final SavePlace _savePlace;
  final SaveMission _saveMission;
  final AuthRepository _auth;
  final Uuid _uuid;

  StreamSubscription<List<Titik>>? _placesSubscription;

  Future<void> _onStarted(
    NaturalStarted event,
    Emitter<NaturalState> emit,
  ) async {
    await _placesSubscription?.cancel();
    _placesSubscription = _watchPlaces().listen(
      (places) => add(NaturalPlacesUpdated(places)),
    );
    emit(state.copyWith(loading: false, places: state.places));
  }

  Future<void> _onParse(
    NaturalParseRequested event,
    Emitter<NaturalState> emit,
  ) async {
    final text = state.text.trim();
    if (text.isEmpty) {
      emit(state.copyWith(failure: NaturalFailure.empty));
      return;
    }
    if (text.length > 500) {
      emit(state.copyWith(failure: NaturalFailure.tooLong));
      return;
    }
    emit(state.copyWith(parsing: true, clearFailure: true, saved: false));
    try {
      final draft = await _parse(text, localeCode: 'id');
      final match = _matchPlace(draft.placeName);
      emit(
        state.copyWith(
          parsing: false,
          draft: draft,
          selectedPlace: match,
          clearSelectedPlace: match == null,
          clearSuggestion: true,
        ),
      );
    } on DiscoveryException catch (error) {
      emit(
        state.copyWith(
          parsing: false,
          failure: error.rateLimited
              ? NaturalFailure.rateLimited
              : NaturalFailure.unavailable,
        ),
      );
    } catch (_) {
      emit(state.copyWith(parsing: false, failure: NaturalFailure.unavailable));
    }
  }

  void _onTitle(NaturalDraftTitleChanged event, Emitter<NaturalState> emit) {
    final draft = state.draft;
    if (draft == null) return;
    emit(
      state.copyWith(
        draft: draft.copyWith(title: event.title),
        clearFailure: true,
      ),
    );
  }

  void _onPlaceName(
    NaturalDraftPlaceNameChanged event,
    Emitter<NaturalState> emit,
  ) {
    final draft = state.draft;
    if (draft == null) return;
    final match = _matchPlace(event.name);
    emit(
      state.copyWith(
        draft: draft.copyWith(placeName: event.name),
        selectedPlace: match,
        clearSelectedPlace: match == null,
        clearSuggestion: true,
        clearFailure: true,
      ),
    );
  }

  void _onPlaceSelected(
    NaturalPlaceSelected event,
    Emitter<NaturalState> emit,
  ) {
    final draft = state.draft;
    emit(
      state.copyWith(
        selectedPlace: event.place,
        clearSelectedPlace: event.place == null,
        clearSuggestion: event.place != null,
        draft: draft == null || event.place == null
            ? draft
            : draft.copyWith(placeName: event.place!.name),
        clearFailure: true,
      ),
    );
  }

  void _onSuggestionSelected(
    NaturalSuggestionSelected event,
    Emitter<NaturalState> emit,
  ) {
    final suggestion = event.suggestion;
    final draft = state.draft;
    emit(
      state.copyWith(
        suggestion: suggestion,
        clearSelectedPlace: true,
        draft: draft?.copyWith(
          placeName: suggestion.name,
          address: suggestion.address,
        ),
        clearFailure: true,
      ),
    );
  }

  Future<void> _onSave(
    NaturalSaveRequested event,
    Emitter<NaturalState> emit,
  ) async {
    final draft = state.draft;
    if (draft == null) return;
    if (draft.title.trim().isEmpty) {
      emit(state.copyWith(failure: NaturalFailure.empty));
      return;
    }
    final selected = state.selectedPlace;
    final suggestion = state.suggestion;
    if (selected == null && suggestion == null) {
      emit(state.copyWith(failure: NaturalFailure.noPlace));
      return;
    }
    emit(state.copyWith(saving: true, clearFailure: true, saved: false));
    try {
      final now = DateTime.now();
      final user = _auth.currentUser;
      final ownerId = user?.id ?? AppConfig.demoUserId;
      var placeId = selected?.id;
      if (placeId == null) {
        final place = Titik(
          id: _uuid.v4(),
          ownerId: ownerId,
          name: suggestion!.name.trim(),
          address: suggestion.address.trim(),
          latitude: suggestion.latitude,
          longitude: suggestion.longitude,
          radiusMeters: 150,
          createdAt: now,
          updatedAt: now,
        );
        await _savePlace(place);
        placeId = place.id;
      }
      final mission = SinggahMission(
        id: _uuid.v4(),
        ownerId: ownerId,
        placeId: placeId,
        title: draft.title.trim(),
        note: draft.note.trim(),
        trigger: draft.trigger,
        repeatDays: draft.repeatDays,
        windowStartMinutes: draft.windowStartMinutes,
        windowEndMinutes: draft.windowEndMinutes,
        createdAt: now,
        updatedAt: now,
      );
      await _saveMission(mission);
      emit(state.copyWith(saving: false, saved: true));
    } catch (_) {
      emit(state.copyWith(saving: false, failure: NaturalFailure.save));
    }
  }

  Titik? _matchPlace(String name) {
    final needle = name.trim().toLowerCase();
    if (needle.length < 2) return null;
    for (final place in state.places) {
      final candidate = place.name.toLowerCase();
      if (candidate == needle ||
          candidate.contains(needle) ||
          needle.contains(candidate)) {
        return place;
      }
    }
    return null;
  }

  void setText(String value) => add(NaturalTextChanged(value));
  void parse() => add(const NaturalParseRequested());
  void setTitle(String value) => add(NaturalDraftTitleChanged(value));
  void setPlaceName(String value) => add(NaturalDraftPlaceNameChanged(value));
  void setTrigger(MissionTrigger value) =>
      add(NaturalDraftTriggerChanged(value));
  void setRepeatDays(Set<int> days) => add(NaturalDraftRepeatChanged(days));
  void setWindow(int start, int end) =>
      add(NaturalDraftWindowChanged(start: start, end: end));
  void selectPlace(Titik? place) => add(NaturalPlaceSelected(place));
  void selectSuggestion(PlaceSuggestion suggestion) =>
      add(NaturalSuggestionSelected(suggestion));
  void save() => add(const NaturalSaveRequested());
  void reset() => add(const NaturalResetRequested());
  void clearFailure() => add(const NaturalFailureCleared());

  @override
  Future<void> close() async {
    await _placesSubscription?.cancel();
    return super.close();
  }
}

final class NaturalPlacesUpdated extends NaturalEvent {
  const NaturalPlacesUpdated(this.places);
  final List<Titik> places;
}
