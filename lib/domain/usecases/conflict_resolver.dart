import 'package:singgah/core/utils/json_x.dart';

enum ConflictWinner { local, remote, equal }

class ConflictResolution {
  const ConflictResolution(this.winner, this.row);

  final ConflictWinner winner;
  final Map<String, dynamic> row;

  bool get useLocal => winner == ConflictWinner.local;
}

/// Last-write-wins conflict resolution for offline-first rows.
///
/// Rules, in order:
/// 1. A missing side always loses.
/// 2. The newer `updated_at` wins. Tombstones participate like any update,
///    so a delete on one device is not resurrected by a stale edit elsewhere.
/// 3. On an exact tie, a local pending edit wins to avoid discarding work that
///    has not reached the server yet. Otherwise the server row is canonical.
///
/// Clock skew is accepted as a trade-off: client clocks are the only clock
/// available offline. The sync engine pulls before pushing so most skew is
/// bounded by the debounce interval.
class ConflictResolver {
  const ConflictResolver();

  ConflictResolution resolve({
    required Map<String, dynamic>? local,
    required Map<String, dynamic>? remote,
  }) {
    if (local == null && remote == null) {
      return const ConflictResolution(ConflictWinner.equal, {});
    }
    if (local == null) {
      return ConflictResolution(ConflictWinner.remote, remote!);
    }
    if (remote == null) {
      return ConflictResolution(ConflictWinner.local, local);
    }

    final localUpdated = dateOrNull(local['updated_at']);
    final remoteUpdated = dateOrNull(remote['updated_at']);

    if (localUpdated == null && remoteUpdated == null) {
      return _tie(local, remote);
    }
    if (localUpdated == null) {
      return ConflictResolution(ConflictWinner.remote, remote);
    }
    if (remoteUpdated == null) {
      return ConflictResolution(ConflictWinner.local, local);
    }

    final comparison = remoteUpdated.compareTo(localUpdated);
    if (comparison > 0) {
      return ConflictResolution(ConflictWinner.remote, remote);
    }
    if (comparison < 0) {
      return ConflictResolution(ConflictWinner.local, local);
    }
    return _tie(local, remote);
  }

  ConflictResolution _tie(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    if (local['is_pending'] == true) {
      return ConflictResolution(ConflictWinner.local, local);
    }
    return ConflictResolution(ConflictWinner.remote, remote);
  }
}
