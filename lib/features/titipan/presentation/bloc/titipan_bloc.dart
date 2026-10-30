import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/entities/titipan_feed.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/usecases/titipan_usecases.dart';
import 'package:singgah/domain/usecases/titipan_visibility.dart';

enum TitipanTab { inbox, sent }

enum TitipanFailure { load, delete, read, link }

class TitipanState extends Equatable {
  const TitipanState({
    this.loading = true,
    this.feed = const TitipanFeed(),
    this.userId = '',
    this.tab = TitipanTab.inbox,
    this.deleting = false,
    this.failure,
  });

  final bool loading;
  final TitipanFeed feed;
  final String userId;
  final TitipanTab tab;
  final bool deleting;
  final TitipanFailure? failure;

  List<Titipan> get inbox => TitipanVisibility.inbox(
    titipans: feed.titipans,
    recipients: feed.recipients,
    userId: userId,
  );

  List<Titipan> get sent =>
      TitipanVisibility.sent(titipans: feed.titipans, userId: userId);

  List<Titipan> get visible => tab == TitipanTab.inbox ? inbox : sent;

  int get unreadCount => inbox.where(isUnread).length;

  bool isUnread(Titipan titipan) {
    final matches = feed.recipients.where(
      (recipient) =>
          recipient.titipanId == titipan.id && recipient.userId == userId,
    );
    if (matches.isEmpty) return false;
    return matches.every((recipient) => recipient.readAt == null);
  }

  bool isAccepted(Titipan titipan) => TitipanVisibility.isAccepted(
    titipanId: titipan.id,
    userId: userId,
    recipients: feed.recipients,
  );

  TitipanState copyWith({
    bool? loading,
    TitipanFeed? feed,
    String? userId,
    TitipanTab? tab,
    bool? deleting,
    TitipanFailure? failure,
    bool clearFailure = false,
  }) {
    return TitipanState(
      loading: loading ?? this.loading,
      feed: feed ?? this.feed,
      userId: userId ?? this.userId,
      tab: tab ?? this.tab,
      deleting: deleting ?? this.deleting,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [loading, feed, userId, tab, deleting, failure];
}

sealed class TitipanEvent {
  const TitipanEvent();
}

final class TitipanStarted extends TitipanEvent {
  const TitipanStarted();
}

final class TitipanDataReceived extends TitipanEvent {
  const TitipanDataReceived(this.feed);
  final TitipanFeed feed;
}

final class TitipanLoadFailed extends TitipanEvent {
  const TitipanLoadFailed();
}

final class TitipanTabChanged extends TitipanEvent {
  const TitipanTabChanged(this.tab);
  final TitipanTab tab;
}

final class TitipanDeleteRequested extends TitipanEvent {
  const TitipanDeleteRequested(this.id, this.completer);
  final String id;
  final Completer<bool> completer;
}

final class TitipanMarkReadRequested extends TitipanEvent {
  const TitipanMarkReadRequested(this.id);
  final String id;
}

final class TitipanInviteLinkRequested extends TitipanEvent {
  const TitipanInviteLinkRequested(this.titipan, this.completer);
  final Titipan titipan;
  final Completer<String?> completer;
}

final class TitipanRefreshRequested extends TitipanEvent {
  const TitipanRefreshRequested();
}

final class TitipanFailureCleared extends TitipanEvent {
  const TitipanFailureCleared();
}

class TitipanBloc extends Bloc<TitipanEvent, TitipanState> {
  TitipanBloc(
    this._watch,
    this._delete,
    this._markRead,
    this._ensureLink,
    this._refresh,
    AuthRepository auth,
  ) : _userId = auth.currentUser?.id ?? '',
      super(TitipanState(userId: auth.currentUser?.id ?? '')) {
    on<TitipanStarted>(_onStarted);
    on<TitipanDataReceived>(_onData);
    on<TitipanLoadFailed>(
      (event, emit) =>
          emit(state.copyWith(loading: false, failure: TitipanFailure.load)),
    );
    on<TitipanTabChanged>(
      (event, emit) => emit(state.copyWith(tab: event.tab)),
    );
    on<TitipanDeleteRequested>(_onDelete);
    on<TitipanMarkReadRequested>(_onMarkRead);
    on<TitipanInviteLinkRequested>(_onInviteLink);
    on<TitipanRefreshRequested>((event, emit) => _refresh());
    on<TitipanFailureCleared>(
      (event, emit) => emit(state.copyWith(clearFailure: true)),
    );
    add(const TitipanStarted());
  }

  final WatchTitipanFeed _watch;
  final DeleteTitipan _delete;
  final MarkTitipanRead _markRead;
  final EnsureTitipanInviteLink _ensureLink;
  final RefreshTitipan _refresh;
  final String _userId;

  StreamSubscription<TitipanFeed>? _subscription;

  Future<void> _onStarted(
    TitipanStarted event,
    Emitter<TitipanState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _watch().listen(
      (feed) => add(TitipanDataReceived(feed)),
      onError: (_) => add(const TitipanLoadFailed()),
    );
  }

  void _onData(TitipanDataReceived event, Emitter<TitipanState> emit) {
    emit(
      state.copyWith(
        feed: event.feed,
        userId: _userId,
        loading: false,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onDelete(
    TitipanDeleteRequested event,
    Emitter<TitipanState> emit,
  ) async {
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(event.id);
      emit(state.copyWith(deleting: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: TitipanFailure.delete));
      event.completer.complete(false);
    }
  }

  Future<void> _onMarkRead(
    TitipanMarkReadRequested event,
    Emitter<TitipanState> emit,
  ) async {
    try {
      await _markRead(event.id);
    } catch (_) {
      emit(state.copyWith(failure: TitipanFailure.read));
    }
  }

  Future<void> _onInviteLink(
    TitipanInviteLinkRequested event,
    Emitter<TitipanState> emit,
  ) async {
    try {
      final link = await _ensureLink(event.titipan);
      event.completer.complete(link);
    } catch (_) {
      emit(state.copyWith(failure: TitipanFailure.link));
      event.completer.complete(null);
    }
  }

  void setTab(TitipanTab tab) => add(TitipanTabChanged(tab));
  void markRead(String id) => add(TitipanMarkReadRequested(id));
  void refresh() => add(const TitipanRefreshRequested());
  void clearFailure() => add(const TitipanFailureCleared());

  Future<bool> deleteTitipan(String id) async {
    final completer = Completer<bool>();
    add(TitipanDeleteRequested(id, completer));
    return completer.future;
  }

  Future<String?> inviteLink(Titipan titipan) async {
    final completer = Completer<String?>();
    add(TitipanInviteLinkRequested(titipan, completer));
    return completer.future;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
