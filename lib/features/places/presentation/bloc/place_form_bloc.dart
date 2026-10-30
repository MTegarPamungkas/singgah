import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/usecases/device_usecases.dart';
import 'package:singgah/domain/usecases/discovery_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';
import 'package:singgah/domain/usecases/settings_usecases.dart';

enum PlaceFormFailure { load, save, delete, location }

class PlaceFormState extends Equatable {
  const PlaceFormState({
    this.loading = true,
    this.saving = false,
    this.deleting = false,
    this.locating = false,
    this.editing = false,
    this.name = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.radiusMeters = 150,
    this.iconKey = 'pin',
    this.colorHex = '#C94F0E',
    this.saved = false,
    this.deleted = false,
    this.failure,
  });

  final bool loading;
  final bool saving;
  final bool deleting;
  final bool locating;
  final bool editing;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final int radiusMeters;
  final String iconKey;
  final String colorHex;
  final bool saved;
  final bool deleted;
  final PlaceFormFailure? failure;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get canSave =>
      name.trim().isNotEmpty && hasCoordinates && !saving && !deleting;

  PlaceFormState copyWith({
    bool? loading,
    bool? saving,
    bool? deleting,
    bool? locating,
    bool? editing,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    String? iconKey,
    String? colorHex,
    bool? saved,
    bool? deleted,
    PlaceFormFailure? failure,
    bool clearFailure = false,
  }) {
    return PlaceFormState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      locating: locating ?? this.locating,
      editing: editing ?? this.editing,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
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
    locating,
    editing,
    name,
    address,
    latitude,
    longitude,
    radiusMeters,
    iconKey,
    colorHex,
    saved,
    deleted,
    failure,
  ];
}

class PlaceSeed {
  const PlaceSeed({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address = '',
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
}

sealed class PlaceFormEvent {
  const PlaceFormEvent();
}

final class PlaceFormStarted extends PlaceFormEvent {
  const PlaceFormStarted();
}

final class PlaceFormNameChanged extends PlaceFormEvent {
  const PlaceFormNameChanged(this.name);
  final String name;
}

final class PlaceFormAddressChanged extends PlaceFormEvent {
  const PlaceFormAddressChanged(this.address);
  final String address;
}

final class PlaceFormRadiusChanged extends PlaceFormEvent {
  const PlaceFormRadiusChanged(this.radius);
  final int radius;
}

final class PlaceFormIconChanged extends PlaceFormEvent {
  const PlaceFormIconChanged(this.icon);
  final String icon;
}

final class PlaceFormCoordinatesChanged extends PlaceFormEvent {
  const PlaceFormCoordinatesChanged(
    this.latitude,
    this.longitude, {
    this.address,
    this.reverse = true,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final bool reverse;
}

final class PlaceFormUseCurrentLocationRequested extends PlaceFormEvent {
  const PlaceFormUseCurrentLocationRequested();
}

final class PlaceFormSaveRequested extends PlaceFormEvent {
  const PlaceFormSaveRequested();
}

final class PlaceFormDeleteRequested extends PlaceFormEvent {
  const PlaceFormDeleteRequested();
}

final class PlaceFormFailureCleared extends PlaceFormEvent {
  const PlaceFormFailureCleared();
}

class PlaceFormBloc extends Bloc<PlaceFormEvent, PlaceFormState> {
  PlaceFormBloc({
    required GetPlace getPlace,
    required SavePlace savePlace,
    required DeletePlace deletePlace,
    required GetCurrentLocation getCurrentLocation,
    required ReverseGeocode reverseGeocode,
    required GetSettings getSettings,
    required AuthRepository auth,
    required this.placeId,
    this.seed,
    Uuid? uuid,
  }) : _getPlace = getPlace,
       _savePlace = savePlace,
       _deletePlace = deletePlace,
       _getCurrentLocation = getCurrentLocation,
       _reverseGeocode = reverseGeocode,
       _getSettings = getSettings,
       _auth = auth,
       _uuid = uuid ?? const Uuid(),
       super(const PlaceFormState()) {
    on<PlaceFormStarted>(_onStarted);
    on<PlaceFormNameChanged>(
      (event, emit) =>
          emit(state.copyWith(name: event.name, clearFailure: true)),
    );
    on<PlaceFormAddressChanged>(
      (event, emit) => emit(state.copyWith(address: event.address)),
    );
    on<PlaceFormRadiusChanged>(
      (event, emit) =>
          emit(state.copyWith(radiusMeters: event.radius.clamp(100, 2000))),
    );
    on<PlaceFormIconChanged>(
      (event, emit) => emit(state.copyWith(iconKey: event.icon)),
    );
    on<PlaceFormCoordinatesChanged>(_onCoordinates);
    on<PlaceFormUseCurrentLocationRequested>(_onCurrentLocation);
    on<PlaceFormSaveRequested>(_onSave);
    on<PlaceFormDeleteRequested>(_onDelete);
    on<PlaceFormFailureCleared>(
      (event, emit) => emit(state.copyWith(clearFailure: true)),
    );
    add(const PlaceFormStarted());
  }

  final GetPlace _getPlace;
  final SavePlace _savePlace;
  final DeletePlace _deletePlace;
  final GetCurrentLocation _getCurrentLocation;
  final ReverseGeocode _reverseGeocode;
  final GetSettings _getSettings;
  final AuthRepository _auth;
  final Uuid _uuid;
  final String? placeId;
  final PlaceSeed? seed;

  Future<void> _onStarted(
    PlaceFormStarted event,
    Emitter<PlaceFormState> emit,
  ) async {
    final settings = await _getSettings();
    if (placeId != null) {
      final place = await _getPlace(placeId!);
      if (place != null) {
        emit(
          PlaceFormState(
            loading: false,
            editing: true,
            name: place.name,
            address: place.address,
            latitude: place.latitude,
            longitude: place.longitude,
            radiusMeters: place.radiusMeters,
            iconKey: place.iconKey,
            colorHex: place.colorHex,
          ),
        );
        return;
      }
    }
    emit(
      PlaceFormState(
        loading: false,
        editing: false,
        name: seed?.name ?? '',
        address: seed?.address ?? '',
        latitude: seed?.latitude,
        longitude: seed?.longitude,
        radiusMeters: settings.defaultRadiusMeters,
      ),
    );
  }

  Future<void> _onCoordinates(
    PlaceFormCoordinatesChanged event,
    Emitter<PlaceFormState> emit,
  ) async {
    emit(
      state.copyWith(
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address ?? state.address,
        clearFailure: true,
      ),
    );
    if (!event.reverse) return;
    final address = await _reverseGeocode(
      event.latitude,
      event.longitude,
      localeCode: _localeCode(),
    );
    if (address != null && address.trim().isNotEmpty) {
      emit(state.copyWith(address: address));
    }
  }

  Future<void> _onCurrentLocation(
    PlaceFormUseCurrentLocationRequested event,
    Emitter<PlaceFormState> emit,
  ) async {
    emit(state.copyWith(locating: true, clearFailure: true));
    final location = await _getCurrentLocation();
    if (location == null) {
      emit(state.copyWith(locating: false, failure: PlaceFormFailure.location));
      return;
    }
    emit(
      state.copyWith(
        locating: false,
        latitude: location.point.latitude,
        longitude: location.point.longitude,
      ),
    );
    final address = await _reverseGeocode(
      location.point.latitude,
      location.point.longitude,
      localeCode: _localeCode(),
    );
    if (address != null && address.trim().isNotEmpty) {
      emit(state.copyWith(address: address));
    }
  }

  Future<void> _onSave(
    PlaceFormSaveRequested event,
    Emitter<PlaceFormState> emit,
  ) async {
    if (!state.canSave) return;
    emit(state.copyWith(saving: true, clearFailure: true, saved: false));
    try {
      final now = DateTime.now();
      final place = Titik(
        id: placeId ?? _uuid.v4(),
        ownerId: _auth.currentUser?.id ?? AppConfig.demoUserId,
        name: state.name.trim(),
        address: state.address.trim(),
        latitude: state.latitude!,
        longitude: state.longitude!,
        radiusMeters: state.radiusMeters.clamp(100, 2000),
        iconKey: state.iconKey,
        colorHex: state.colorHex,
        createdAt: now,
        updatedAt: now,
      );
      await _savePlace(place);
      emit(state.copyWith(saving: false, saved: true));
    } catch (_) {
      emit(state.copyWith(saving: false, failure: PlaceFormFailure.save));
    }
  }

  Future<void> _onDelete(
    PlaceFormDeleteRequested event,
    Emitter<PlaceFormState> emit,
  ) async {
    final id = placeId;
    if (id == null) return;
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _deletePlace(id);
      emit(state.copyWith(deleting: false, deleted: true));
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: PlaceFormFailure.delete));
    }
  }

  void setName(String value) => add(PlaceFormNameChanged(value));
  void setAddress(String value) => add(PlaceFormAddressChanged(value));
  void setRadius(int value) => add(PlaceFormRadiusChanged(value));
  void setIcon(String value) => add(PlaceFormIconChanged(value));
  void setCoordinates(
    double latitude,
    double longitude, {
    String? address,
    bool reverse = true,
  }) => add(
    PlaceFormCoordinatesChanged(
      latitude,
      longitude,
      address: address,
      reverse: reverse,
    ),
  );
  void useCurrentLocation() =>
      add(const PlaceFormUseCurrentLocationRequested());
  void save() => add(const PlaceFormSaveRequested());
  void delete() => add(const PlaceFormDeleteRequested());
  void clearFailure() => add(const PlaceFormFailureCleared());

  String _localeCode() {
    // Reverse geocoding is a nicety; the profile locale is not worth a DB read
    // here, and both supported locales read OSM names acceptably.
    return 'id';
  }
}
