import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/domain/entities/geo_point.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';
import 'package:singgah/domain/usecases/device_usecases.dart';
import 'package:singgah/domain/usecases/discovery_usecases.dart';

class PlacePickerState extends Equatable {
  const PlacePickerState({
    this.query = '',
    this.results = const [],
    this.loading = false,
    this.searching = false,
    this.locating = false,
    this.center,
    this.address,
    this.error = false,
    this.rateLimited = false,
  });

  final String query;
  final List<PlaceSuggestion> results;
  final bool loading;
  final bool searching;
  final bool locating;
  final GeoPoint? center;
  final String? address;
  final bool error;
  final bool rateLimited;

  PlacePickerState copyWith({
    String? query,
    List<PlaceSuggestion>? results,
    bool? loading,
    bool? searching,
    bool? locating,
    GeoPoint? center,
    String? address,
    bool? error,
    bool? rateLimited,
  }) {
    return PlacePickerState(
      query: query ?? this.query,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      searching: searching ?? this.searching,
      locating: locating ?? this.locating,
      center: center ?? this.center,
      address: address ?? this.address,
      error: error ?? this.error,
      rateLimited: rateLimited ?? this.rateLimited,
    );
  }

  @override
  List<Object?> get props => [
    query,
    results,
    loading,
    searching,
    locating,
    center,
    address,
    error,
    rateLimited,
  ];
}

sealed class PlacePickerEvent {
  const PlacePickerEvent();
}

final class PlacePickerStarted extends PlacePickerEvent {
  const PlacePickerStarted();
}

final class PlacePickerQueryChanged extends PlacePickerEvent {
  const PlacePickerQueryChanged(this.query);
  final String query;
}

final class PlacePickerSearchRequested extends PlacePickerEvent {
  const PlacePickerSearchRequested();
}

final class PlacePickerCurrentLocationRequested extends PlacePickerEvent {
  const PlacePickerCurrentLocationRequested();
}

final class PlacePickerPointSelected extends PlacePickerEvent {
  const PlacePickerPointSelected(this.point);
  final GeoPoint point;
}

final class PlacePickerFailedCleared extends PlacePickerEvent {
  const PlacePickerFailedCleared();
}

class PlacePickerBloc extends Bloc<PlacePickerEvent, PlacePickerState> {
  PlacePickerBloc(this._search, this._currentLocation, this._reverseGeocode)
    : super(const PlacePickerState()) {
    on<PlacePickerStarted>(_onStarted);
    on<PlacePickerQueryChanged>(_onQueryChanged);
    on<PlacePickerSearchRequested>(_onSearch);
    on<PlacePickerCurrentLocationRequested>(_onCurrentLocation);
    on<PlacePickerPointSelected>(_onPointSelected);
    on<PlacePickerFailedCleared>(
      (event, emit) => emit(state.copyWith(error: false, rateLimited: false)),
    );
    add(const PlacePickerStarted());
  }

  final SearchPlaces _search;
  final GetCurrentLocation _currentLocation;
  final ReverseGeocode _reverseGeocode;

  Timer? _debounce;

  Future<void> _onStarted(
    PlacePickerStarted event,
    Emitter<PlacePickerState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final location = await _currentLocation();
    if (location != null) {
      emit(
        state.copyWith(loading: false, center: location.point, locating: false),
      );
    } else {
      emit(state.copyWith(loading: false));
    }
  }

  void _onQueryChanged(
    PlacePickerQueryChanged event,
    Emitter<PlacePickerState> emit,
  ) {
    emit(state.copyWith(query: event.query, error: false, rateLimited: false));
    _debounce?.cancel();
    if (event.query.trim().length < 2) {
      emit(state.copyWith(results: const [], searching: false));
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => add(const PlacePickerSearchRequested()),
    );
  }

  Future<void> _onSearch(
    PlacePickerSearchRequested event,
    Emitter<PlacePickerState> emit,
  ) async {
    final query = state.query.trim();
    if (query.length < 2) return;
    emit(state.copyWith(searching: true, error: false, rateLimited: false));
    try {
      final results = await _search(query, localeCode: 'id');
      emit(state.copyWith(results: results, searching: false));
    } on DiscoveryException catch (error) {
      emit(
        state.copyWith(
          searching: false,
          error: true,
          rateLimited: error.rateLimited,
        ),
      );
    } catch (_) {
      emit(state.copyWith(searching: false, error: true));
    }
  }

  Future<void> _onCurrentLocation(
    PlacePickerCurrentLocationRequested event,
    Emitter<PlacePickerState> emit,
  ) async {
    emit(state.copyWith(locating: true));
    final location = await _currentLocation();
    if (location == null) {
      emit(state.copyWith(locating: false));
      return;
    }
    final address = await _reverseGeocode(
      location.point.latitude,
      location.point.longitude,
      localeCode: 'id',
    );
    emit(
      state.copyWith(locating: false, center: location.point, address: address),
    );
  }

  Future<void> _onPointSelected(
    PlacePickerPointSelected event,
    Emitter<PlacePickerState> emit,
  ) async {
    emit(state.copyWith(center: event.point, loading: false));
    final address = await _reverseGeocode(
      event.point.latitude,
      event.point.longitude,
      localeCode: 'id',
    );
    if (address != null && address.trim().isNotEmpty) {
      emit(state.copyWith(address: address));
    }
  }

  void setQuery(String value) => add(PlacePickerQueryChanged(value));
  void search() => add(const PlacePickerSearchRequested());
  void selectPoint(GeoPoint point) => add(PlacePickerPointSelected(point));
  void useCurrentLocation() => add(const PlacePickerCurrentLocationRequested());
  void clearFailure() => add(const PlacePickerFailedCleared());

  @override
  Future<void> close() async {
    _debounce?.cancel();
    return super.close();
  }
}
