import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/domain/entities/app_settings.dart';
import 'package:singgah/domain/entities/geofence_summary.dart';
import 'package:singgah/domain/services/geofence_manager.dart';
import 'package:singgah/domain/services/location_service.dart';
import 'package:singgah/domain/services/notification_service.dart';
import 'package:singgah/domain/repositories/settings_repository.dart';
import 'package:singgah/domain/usecases/settings_usecases.dart';

class PermissionsState extends Equatable {
  const PermissionsState({
    this.loading = true,
    this.busy = false,
    this.summary = const GeofenceSummary(),
    this.serviceEnabled = false,
    this.notificationsRequested = false,
    this.notificationsGranted = false,
    this.message,
  });

  final bool loading;
  final bool busy;
  final GeofenceSummary summary;
  final bool serviceEnabled;
  final bool notificationsRequested;
  final bool notificationsGranted;
  final String? message;

  bool get foregroundGranted =>
      summary.permission == LocationPermissionState.grantedForeground ||
      summary.permission == LocationPermissionState.grantedBackground;

  bool get backgroundGranted =>
      summary.permission == LocationPermissionState.grantedBackground;

  PermissionsState copyWith({
    bool? loading,
    bool? busy,
    GeofenceSummary? summary,
    bool? serviceEnabled,
    bool? notificationsRequested,
    bool? notificationsGranted,
    String? message,
    bool clearMessage = false,
  }) {
    return PermissionsState(
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      summary: summary ?? this.summary,
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      notificationsRequested:
          notificationsRequested ?? this.notificationsRequested,
      notificationsGranted: notificationsGranted ?? this.notificationsGranted,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    busy,
    summary,
    serviceEnabled,
    notificationsRequested,
    notificationsGranted,
    message,
  ];
}

sealed class PermissionsEvent {
  const PermissionsEvent();
}

final class PermissionsStarted extends PermissionsEvent {
  const PermissionsStarted();
}

final class PermissionsSummaryReceived extends PermissionsEvent {
  const PermissionsSummaryReceived(this.summary);
  final GeofenceSummary summary;
}

final class PermissionsForegroundRequested extends PermissionsEvent {
  const PermissionsForegroundRequested();
}

final class PermissionsBackgroundRequested extends PermissionsEvent {
  const PermissionsBackgroundRequested();
}

final class PermissionsNotificationRequested extends PermissionsEvent {
  const PermissionsNotificationRequested();
}

final class PermissionsOpenSettingsRequested extends PermissionsEvent {
  const PermissionsOpenSettingsRequested();
}

final class PermissionsOpenLocationSettingsRequested extends PermissionsEvent {
  const PermissionsOpenLocationSettingsRequested();
}

final class PermissionsRefreshRequested extends PermissionsEvent {
  const PermissionsRefreshRequested();
}

final class PermissionsRemindersToggled extends PermissionsEvent {
  const PermissionsRemindersToggled(this.enabled);
  final bool enabled;
}

class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  PermissionsBloc(
    this._location,
    this._notifications,
    this._geofences,
    this._settings,
    this._getSettings,
    this._updateSettings,
  ) : super(const PermissionsState()) {
    on<PermissionsStarted>(_onStarted);
    on<PermissionsSummaryReceived>(
      (event, emit) => emit(
        state.copyWith(summary: event.summary, loading: false, busy: false),
      ),
    );
    on<PermissionsForegroundRequested>(_onForeground);
    on<PermissionsBackgroundRequested>(_onBackground);
    on<PermissionsNotificationRequested>(_onNotifications);
    on<PermissionsOpenSettingsRequested>(_onOpenSettings);
    on<PermissionsOpenLocationSettingsRequested>(_onOpenLocation);
    on<PermissionsRefreshRequested>(_onRefresh);
    on<PermissionsRemindersToggled>(_onRemindersToggled);
    add(const PermissionsStarted());
  }

  final LocationService _location;
  final NotificationService _notifications;
  final GeofenceManager _geofences;
  final SettingsRepository _settings;
  final GetSettings _getSettings;
  final UpdateSettings _updateSettings;

  StreamSubscription<GeofenceSummary>? _subscription;

  Future<void> _onStarted(
    PermissionsStarted event,
    Emitter<PermissionsState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _geofences.summaries.listen(
      (summary) => add(PermissionsSummaryReceived(summary)),
    );
    await _refresh(emit);
  }

  Future<void> _refresh(Emitter<PermissionsState> emit) async {
    final enabled = await _location.isServiceEnabled();
    final summary = await _geofences.summary();
    if (isClosed) return;
    emit(
      state.copyWith(loading: false, serviceEnabled: enabled, summary: summary),
    );
  }

  Future<void> _onForeground(
    PermissionsForegroundRequested event,
    Emitter<PermissionsState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    await _location.requestForeground();
    await _geofences.refresh(force: true);
    await _refresh(emit);
    emit(state.copyWith(busy: false));
  }

  Future<void> _onBackground(
    PermissionsBackgroundRequested event,
    Emitter<PermissionsState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    await _location.requestBackground();
    await _geofences.refresh(force: true);
    await _refresh(emit);
    emit(state.copyWith(busy: false));
  }

  Future<void> _onNotifications(
    PermissionsNotificationRequested event,
    Emitter<PermissionsState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final granted = await _notifications.requestPermission();
    emit(
      state.copyWith(
        busy: false,
        notificationsRequested: true,
        notificationsGranted: granted,
      ),
    );
  }

  Future<void> _onOpenSettings(
    PermissionsOpenSettingsRequested event,
    Emitter<PermissionsState> emit,
  ) async {
    await _location.openAppSettings();
  }

  Future<void> _onOpenLocation(
    PermissionsOpenLocationSettingsRequested event,
    Emitter<PermissionsState> emit,
  ) async {
    await _location.openLocationSettings();
  }

  Future<void> _onRefresh(
    PermissionsRefreshRequested event,
    Emitter<PermissionsState> emit,
  ) async {
    await _geofences.refresh(force: true);
    await _refresh(emit);
  }

  Future<void> _onRemindersToggled(
    PermissionsRemindersToggled event,
    Emitter<PermissionsState> emit,
  ) async {
    final current = await _getSettings();
    await _updateSettings(
      current.copyWith(locationRemindersEnabled: event.enabled),
    );
    if (event.enabled) {
      await _location.requestForeground();
      await _notifications.requestPermission();
    }
    await _geofences.refresh(force: true);
    await _refresh(emit);
  }

  Future<AppSettings> currentSettings() => _settings.getSettings();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
