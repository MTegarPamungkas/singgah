import 'package:equatable/equatable.dart';

enum SyncPhase { demo, idle, syncing, offline, error }

class SyncStatus extends Equatable {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.message,
  });

  factory SyncStatus.demo({int pendingCount = 0}) => SyncStatus(
    phase: SyncPhase.demo,
    pendingCount: pendingCount,
    message: 'Local demo mode',
  );

  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? message;

  bool get isBusy => phase == SyncPhase.syncing;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? message,
    bool clearMessage = false,
  }) {
    return SyncStatus(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [phase, pendingCount, lastSyncedAt, message];
}
