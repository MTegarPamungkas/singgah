import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/usecases/titipan_usecases.dart';

enum InviteFailure { invalid, alreadyAccepted, network }

class InviteState extends Equatable {
  const InviteState({
    this.loading = false,
    this.accepting = false,
    this.accepted = false,
    this.titipan,
    this.failure,
  });

  final bool loading;
  final bool accepting;
  final bool accepted;
  final Titipan? titipan;
  final InviteFailure? failure;

  InviteState copyWith({
    bool? loading,
    bool? accepting,
    bool? accepted,
    Titipan? titipan,
    InviteFailure? failure,
    bool clearFailure = false,
  }) {
    return InviteState(
      loading: loading ?? this.loading,
      accepting: accepting ?? this.accepting,
      accepted: accepted ?? this.accepted,
      titipan: titipan ?? this.titipan,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [loading, accepting, accepted, titipan, failure];
}

sealed class InviteEvent {
  const InviteEvent();
}

final class InviteStarted extends InviteEvent {
  const InviteStarted();
}

final class InviteAcceptedRequested extends InviteEvent {
  const InviteAcceptedRequested();
}

final class InviteFailureCleared extends InviteEvent {
  const InviteFailureCleared();
}

class InviteBloc extends Bloc<InviteEvent, InviteState> {
  InviteBloc({
    required AcceptTitipanInvite acceptInvite,
    required GetTitipan getTitipan,
    required AuthRepository auth,
    required this.token,
  }) : _acceptInvite = acceptInvite,
       _getTitipan = getTitipan,
       _auth = auth,
       super(const InviteState()) {
    on<InviteStarted>(_onStarted);
    on<InviteAcceptedRequested>(_onAccept);
    on<InviteFailureCleared>(
      (event, emit) => emit(state.copyWith(clearFailure: true)),
    );
    add(const InviteStarted());
  }

  final AcceptTitipanInvite _acceptInvite;
  final GetTitipan _getTitipan;
  final AuthRepository _auth;
  final String token;

  Future<void> _onStarted(
    InviteStarted event,
    Emitter<InviteState> emit,
  ) async {
    if (token.trim().isEmpty) {
      emit(state.copyWith(failure: InviteFailure.invalid));
      return;
    }
    if (_auth.currentUser == null) {
      emit(state.copyWith(failure: InviteFailure.invalid));
      return;
    }
  }

  Future<void> _onAccept(
    InviteAcceptedRequested event,
    Emitter<InviteState> emit,
  ) async {
    if (state.accepting) return;
    emit(state.copyWith(accepting: true, clearFailure: true));
    try {
      final titipan = await _acceptInvite(token);
      final fresh = await _getTitipan(titipan.id) ?? titipan;
      emit(state.copyWith(accepting: false, accepted: true, titipan: fresh));
    } catch (error) {
      final text = error.toString().toLowerCase();
      final failure = text.contains('already') || text.contains('sudah')
          ? InviteFailure.alreadyAccepted
          : text.contains('invalid') ||
                text.contains('not found') ||
                text.contains('tidak')
          ? InviteFailure.invalid
          : InviteFailure.network;
      emit(state.copyWith(accepting: false, failure: failure));
    }
  }

  void accept() => add(const InviteAcceptedRequested());
  void clearFailure() => add(const InviteFailureCleared());
}
