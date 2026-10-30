import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/domain/entities/singgah_event.dart';
import 'package:singgah/domain/usecases/history_usecases.dart';

enum HistoryFailure { load, clear }

class HistoryState extends Equatable {
  const HistoryState({
    this.loading = true,
    this.events = const [],
    this.clearing = false,
    this.failure,
  });

  final bool loading;
  final List<SinggahEvent> events;
  final bool clearing;
  final HistoryFailure? failure;

  HistoryState copyWith({
    bool? loading,
    List<SinggahEvent>? events,
    bool? clearing,
    HistoryFailure? failure,
    bool clearFailure = false,
  }) {
    return HistoryState(
      loading: loading ?? this.loading,
      events: events ?? this.events,
      clearing: clearing ?? this.clearing,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [loading, events, clearing, failure];
}

sealed class HistoryEvent {
  const HistoryEvent();
}

final class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

final class HistoryDataReceived extends HistoryEvent {
  const HistoryDataReceived(this.events);
  final List<SinggahEvent> events;
}

final class HistoryLoadFailed extends HistoryEvent {
  const HistoryLoadFailed();
}

final class HistoryClearRequested extends HistoryEvent {
  const HistoryClearRequested(this.completer);
  final Completer<bool> completer;
}

final class HistoryFailureCleared extends HistoryEvent {
  const HistoryFailureCleared();
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc(this._watch, this._clear, this._drain)
    : super(const HistoryState()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryDataReceived>(_onData);
    on<HistoryLoadFailed>(
      (event, emit) =>
          emit(state.copyWith(loading: false, failure: HistoryFailure.load)),
    );
    on<HistoryClearRequested>(_onClear);
    on<HistoryFailureCleared>(
      (event, emit) => emit(state.copyWith(clearFailure: true)),
    );
    add(const HistoryStarted());
  }

  final WatchHistory _watch;
  final ClearHistory _clear;
  final DrainNativeTransitions _drain;
  StreamSubscription<List<SinggahEvent>>? _subscription;

  Future<void> _onStarted(
    HistoryStarted event,
    Emitter<HistoryState> emit,
  ) async {
    await _subscription?.cancel();
    await _drain();
    _subscription = _watch().listen(
      (events) => add(HistoryDataReceived(events)),
      onError: (_) => add(const HistoryLoadFailed()),
    );
  }

  void _onData(HistoryDataReceived event, Emitter<HistoryState> emit) {
    emit(
      state.copyWith(events: event.events, loading: false, clearFailure: true),
    );
  }

  Future<void> _onClear(
    HistoryClearRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(clearing: true, clearFailure: true));
    try {
      await _clear();
      emit(state.copyWith(clearing: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(clearing: false, failure: HistoryFailure.clear));
      event.completer.complete(false);
    }
  }

  Future<bool> clearHistory() async {
    final completer = Completer<bool>();
    add(HistoryClearRequested(completer));
    return completer.future;
  }

  void clearFailure() => add(const HistoryFailureCleared());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
