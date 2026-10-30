import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/domain/entities/app_settings.dart';
import 'package:singgah/domain/usecases/settings_usecases.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

final class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

final class SettingsReceived extends SettingsEvent {
  const SettingsReceived(this.settings);
  final AppSettings settings;
}

final class SettingsThemeChanged extends SettingsEvent {
  const SettingsThemeChanged(this.mode);
  final AppThemeMode mode;
}

final class SettingsLocaleChanged extends SettingsEvent {
  const SettingsLocaleChanged(this.code);
  final String code;
}

final class SettingsBiometricChanged extends SettingsEvent {
  const SettingsBiometricChanged(this.enabled);
  final bool enabled;
}

final class SettingsRemindersChanged extends SettingsEvent {
  const SettingsRemindersChanged(this.enabled);
  final bool enabled;
}

final class SettingsKeepHistoryChanged extends SettingsEvent {
  const SettingsKeepHistoryChanged(this.enabled);
  final bool enabled;
}

final class SettingsRadiusChanged extends SettingsEvent {
  const SettingsRadiusChanged(this.meters);
  final int meters;
}

final class SettingsOnboardingCompleted extends SettingsEvent {
  const SettingsOnboardingCompleted(this.completer);
  final Completer<void> completer;
}

class SettingsBloc extends Bloc<SettingsEvent, AppSettings> {
  SettingsBloc(this._watch, this._get, this._update)
    : super(const AppSettings()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsReceived>(_onReceived);
    on<SettingsThemeChanged>(
      (e, emit) => _save(e, emit, (s) => s.copyWith(themeMode: e.mode)),
    );
    on<SettingsLocaleChanged>(
      (e, emit) => _save(e, emit, (s) => s.copyWith(localeCode: e.code)),
    );
    on<SettingsBiometricChanged>(
      (e, emit) => _save(e, emit, (s) => s.copyWith(biometricLock: e.enabled)),
    );
    on<SettingsRemindersChanged>(
      (e, emit) => _save(
        e,
        emit,
        (s) => s.copyWith(locationRemindersEnabled: e.enabled),
      ),
    );
    on<SettingsKeepHistoryChanged>(
      (e, emit) => _save(e, emit, (s) => s.copyWith(keepHistory: e.enabled)),
    );
    on<SettingsRadiusChanged>(
      (e, emit) => _save(
        e,
        emit,
        (s) => s.copyWith(defaultRadiusMeters: e.meters.clamp(100, 2000)),
      ),
    );
    on<SettingsOnboardingCompleted>(_onOnboardingCompleted);
    add(const SettingsStarted());
  }

  final WatchSettings _watch;
  final GetSettings _get;
  final UpdateSettings _update;
  StreamSubscription<AppSettings>? _subscription;

  Future<void> _onStarted(
    SettingsStarted event,
    Emitter<AppSettings> emit,
  ) async {
    await _subscription?.cancel();
    final initial = await _get();
    if (!isClosed) emit(initial);
    _subscription = _watch().listen(
      (settings) => add(SettingsReceived(settings)),
    );
  }

  void _onReceived(SettingsReceived event, Emitter<AppSettings> emit) {
    emit(event.settings);
  }

  Future<void> _save(
    SettingsEvent event,
    Emitter<AppSettings> emit,
    AppSettings Function(AppSettings current) transform,
  ) async {
    final next = transform(state);
    emit(next);
    try {
      await _update(next);
    } catch (_) {
      // Local preference writes are best effort; the next watch will correct.
    }
  }

  void setThemeMode(AppThemeMode mode) => add(SettingsThemeChanged(mode));
  void setLocale(String code) => add(SettingsLocaleChanged(code));
  void setBiometric(bool enabled) => add(SettingsBiometricChanged(enabled));
  void setReminders(bool enabled) => add(SettingsRemindersChanged(enabled));
  void setKeepHistory(bool enabled) => add(SettingsKeepHistoryChanged(enabled));
  void setRadius(int meters) => add(SettingsRadiusChanged(meters));

  /// Persists first, then lets the caller navigate. The router reads the
  /// onboarding flag synchronously, so the completer only resolves after the
  /// new state is visible; otherwise navigation would bounce back.
  Future<void> completeOnboarding() async {
    final completer = Completer<void>();
    add(SettingsOnboardingCompleted(completer));
    await completer.future;
  }

  Future<void> _onOnboardingCompleted(
    SettingsOnboardingCompleted event,
    Emitter<AppSettings> emit,
  ) async {
    final next = state.copyWith(onboardingCompleted: true);
    emit(next);
    try {
      await _update(next);
    } catch (_) {
      // The local state is already updated; the next watch will correct it.
    } finally {
      if (!event.completer.isCompleted) event.completer.complete();
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
