import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/domain/entities/sync_status.dart';
import 'package:singgah/domain/usecases/sync_usecases.dart';

sealed class SyncEvent {
  const SyncEvent();
}

final class SyncStarted extends SyncEvent {
  const SyncStarted();
}

final class SyncStatusReceived extends SyncEvent {
  const SyncStatusReceived(this.status);
  final SyncStatus status;
}

final class SyncNowRequested extends SyncEvent {
  const SyncNowRequested();
}

class SyncBloc extends Bloc<SyncEvent, SyncStatus> {
  SyncBloc(this._watch, this._syncNow) : super(const SyncStatus()) {
    on<SyncStarted>(_onStarted);
    on<SyncStatusReceived>((event, emit) => emit(event.status));
    on<SyncNowRequested>((event, emit) => _syncNow());
    add(const SyncStarted());
  }

  final WatchSyncStatus _watch;
  final SyncNow _syncNow;
  StreamSubscription<SyncStatus>? _subscription;

  Future<void> _onStarted(SyncStarted event, Emitter<SyncStatus> emit) async {
    await _subscription?.cancel();
    _subscription = _watch().listen(
      (status) => add(SyncStatusReceived(status)),
    );
  }

  void syncNow() => add(const SyncNowRequested());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
