import 'package:flutter_test/flutter_test.dart';

import 'package:singgah/domain/usecases/conflict_resolver.dart';

void main() {
  const resolver = ConflictResolver();

  test('missing sides lose', () {
    expect(
      resolver.resolve(local: null, remote: null).winner,
      ConflictWinner.equal,
    );
    expect(
      resolver.resolve(local: null, remote: {'id': 'a'}).winner,
      ConflictWinner.remote,
    );
    expect(
      resolver.resolve(local: {'id': 'a'}, remote: null).winner,
      ConflictWinner.local,
    );
  });

  test('newer updated_at wins in both directions', () {
    final older = {'id': 'a', 'updated_at': '2026-10-20T10:00:00Z'};
    final newer = {'id': 'a', 'updated_at': '2026-10-21T10:00:00Z'};
    expect(
      resolver.resolve(local: older, remote: newer).winner,
      ConflictWinner.remote,
    );
    expect(
      resolver.resolve(local: newer, remote: older).winner,
      ConflictWinner.local,
    );
  });

  test('a tombstone can win by being newer', () {
    final live = {'id': 'a', 'updated_at': '2026-10-20T10:00:00Z'};
    final tombstone = {
      'id': 'a',
      'updated_at': '2026-10-22T10:00:00Z',
      'deleted_at': '2026-10-22T10:00:00Z',
    };
    final result = resolver.resolve(local: live, remote: tombstone);
    expect(result.winner, ConflictWinner.remote);
    expect(result.row['deleted_at'], isNotNull);
  });

  test('exact tie prefers local pending edits, otherwise the server', () {
    final timestamp = '2026-10-20T10:00:00Z';
    final pending = {
      'id': 'a',
      'updated_at': timestamp,
      'is_pending': true,
      'name': 'local draft',
    };
    final server = {'id': 'a', 'updated_at': timestamp, 'name': 'server'};
    expect(
      resolver.resolve(local: pending, remote: server).winner,
      ConflictWinner.local,
    );

    final synced = {'id': 'a', 'updated_at': timestamp, 'name': 'local synced'};
    expect(
      resolver.resolve(local: synced, remote: server).winner,
      ConflictWinner.remote,
    );
  });

  test('null timestamps fall back to the pending tie-break', () {
    expect(
      resolver
          .resolve(local: {'id': 'a', 'is_pending': true}, remote: {'id': 'a'})
          .winner,
      ConflictWinner.local,
    );
    expect(
      resolver.resolve(local: {'id': 'a'}, remote: {'id': 'a'}).winner,
      ConflictWinner.remote,
    );
    expect(
      resolver
          .resolve(
            local: {'id': 'a', 'updated_at': '2026-10-20T10:00:00Z'},
            remote: {'id': 'a'},
          )
          .winner,
      ConflictWinner.local,
    );
  });
}
