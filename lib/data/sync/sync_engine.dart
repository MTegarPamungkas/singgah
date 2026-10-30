import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/domain/entities/app_user.dart';
import 'package:singgah/domain/entities/sync_status.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/repositories/sync_repository.dart';
import 'package:singgah/domain/usecases/conflict_resolver.dart';

class SyncEngine implements SyncRepository {
  SyncEngine({
    required LocalStore store,
    required CloudGateway gateway,
    required AuthRepository auth,
    required Connectivity connectivity,
    ConflictResolver? conflictResolver,
  }) : _store = store,
       _gateway = gateway,
       _auth = auth,
       _connectivity = connectivity,
       _resolver = conflictResolver ?? const ConflictResolver();

  final LocalStore _store;
  final CloudGateway _gateway;
  final AuthRepository _auth;
  final Connectivity _connectivity;
  final ConflictResolver _resolver;

  static const List<String> syncTables = [
    'places',
    'missions',
    'titipan',
    'titipan_recipients',
  ];

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  final StreamController<void> _incomingTitipanController =
      StreamController<void>.broadcast();

  SyncStatus _status = const SyncStatus();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<int>? _pendingSubscription;
  StreamSubscription<void>? _changeSubscription;
  StreamSubscription<void>? _inboxSubscription;
  Timer? _syncDebounce;
  Timer? _pullDebounce;
  bool _online = true;
  bool _running = false;
  bool _started = false;
  bool _disposed = false;
  Future<void> _realtimeChain = Future<void>.value();

  @override
  SyncStatus get current => _status;

  bool get isDemoMode => _gateway.isDemo;

  Stream<void> get incomingTitipan => _incomingTitipanController.stream;

  @override
  Stream<SyncStatus> watchStatus() async* {
    yield _status;
    yield* _statusController.stream;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _pendingSubscription = _store.watchOutboxCount().listen((count) {
      _setStatus(_status.copyWith(pendingCount: count));
    });

    try {
      final results = await _connectivity.checkConnectivity();
      _online = !_isOffline(results);
    } catch (_) {
      _online = true;
    }

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final wasOnline = _online;
      _online = !_isOffline(results);
      if (!_online) {
        _setStatus(
          _status.copyWith(
            phase: SyncPhase.offline,
            message: 'No connection. Changes are saved on-device.',
          ),
        );
      } else if (!wasOnline) {
        requestSync();
      }
    });

    _authSubscription = _auth.watchUser().listen((user) {
      if (user == null) {
        _syncRealtimeFor(null);
        _setStatus(
          _status.copyWith(
            phase: SyncPhase.offline,
            message: 'Sign in to sync your Places.',
          ),
        );
      } else {
        // Realtime sockets capture the session at handshake time, so they are
        // rebuilt after sign-in to receive row events as this user.
        _syncRealtimeFor(user);
        requestSync();
      }
    });

    _syncRealtimeFor(_auth.currentUser);

    if (_gateway.isDemo) {
      _setStatus(SyncStatus.demo(pendingCount: _store.outboxItems().length));
      return;
    }

    if (_auth.currentUser == null) {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.offline,
          message: 'Sign in to sync your Places.',
        ),
      );
      return;
    }

    if (_online) {
      requestSync();
    } else {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.offline,
          message: 'No connection. Changes are saved on-device.',
        ),
      );
    }
  }

  @override
  void requestSync() {
    if (_gateway.isDemo) {
      _setStatus(SyncStatus.demo(pendingCount: _store.outboxItems().length));
      return;
    }
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 500), syncNow);
  }

  void _syncRealtimeFor(AppUser? user) {
    _realtimeChain = _realtimeChain.catchError((Object _) {}).then((_) async {
      await _unbindRealtime();
      if (_disposed || user == null || _gateway.isDemo) return;
      await _gateway.resetRealtime();
      if (_disposed) return;
      _changeSubscription = _gateway
          .watchChanges(syncTables)
          .listen((_) => _schedulePull());
      _inboxSubscription = _gateway.watchIncomingTitipan().listen((_) {
        if (!_incomingTitipanController.isClosed) {
          _incomingTitipanController.add(null);
        }
        _schedulePull();
      });
    });
  }

  Future<void> _unbindRealtime() async {
    await _changeSubscription?.cancel();
    _changeSubscription = null;
    await _inboxSubscription?.cancel();
    _inboxSubscription = null;
  }

  void _schedulePull() {
    if (_gateway.isDemo) return;
    _pullDebounce?.cancel();
    _pullDebounce = Timer(
      const Duration(milliseconds: 400),
      () => pullChanges(),
    );
  }

  @override
  Future<void> syncNow() async {
    if (_gateway.isDemo) {
      _setStatus(SyncStatus.demo(pendingCount: _store.outboxItems().length));
      return;
    }
    if (_running) return;
    if (!_online) {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.offline,
          message: 'No connection. Changes are saved on-device.',
        ),
      );
      return;
    }
    if (_auth.currentUser == null) return;

    _running = true;
    _setStatus(
      _status.copyWith(
        phase: SyncPhase.syncing,
        message: null,
        clearMessage: true,
      ),
    );

    try {
      // Pull first so Last-Write-Wins compares against the freshest server
      // state, then push local pending rows.
      await pullChanges(silent: true);
      await _pushOutbox();
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.idle,
          lastSyncedAt: DateTime.now(),
          message: null,
          clearMessage: true,
        ),
      );
    } catch (error) {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.error,
          message: 'Sync paused: $error',
        ),
      );
    } finally {
      _running = false;
    }
  }

  Future<void> pullChanges({bool silent = false}) async {
    if (_gateway.isDemo || !_online || _auth.currentUser == null) return;

    try {
      for (final table in syncTables) {
        var cursor = _store.getMeta('sync_cursor_$table') as String?;
        while (true) {
          final rows = await _gateway.pull(
            table,
            since: cursor == null ? null : DateTime.tryParse(cursor),
            limit: 200,
          );
          if (rows.isEmpty) break;

          for (final row in rows) {
            await _mergeRemoteRow(table, row);
          }

          final lastUpdated = rows.last['updated_at']?.toString();
          if (lastUpdated == null) break;
          cursor = lastUpdated;
          await _store.setMeta('sync_cursor_$table', cursor);
          if (rows.length < 200) break;
        }
      }
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.idle,
          lastSyncedAt: DateTime.now(),
          pendingCount: _store.outboxItems().length,
          message: null,
          clearMessage: true,
        ),
      );
    } catch (error) {
      if (!silent) {
        _setStatus(
          _status.copyWith(
            phase: SyncPhase.error,
            message: 'Could not pull updates: $error',
          ),
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> _mergeRemoteRow(String table, Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final local = _store.get(table, id);
    final resolution = _resolver.resolve(local: local, remote: row);
    if (resolution.winner == ConflictWinner.remote) {
      await _store.put(table, resolution.row);
    }
  }

  Future<void> _pushOutbox() async {
    for (final item in _store.outboxItems()) {
      final id = item['id'] as String;
      final table = item['table'] as String;
      final entityId = item['entity_id'] as String;
      final operation = item['operation'] as String;
      final payload = Map<String, dynamic>.from(
        item['payload'] as Map? ?? const {},
      )..remove('is_pending');

      try {
        if (operation == 'delete') {
          await _gateway.softDelete(
            table,
            entityId,
            DateTime.tryParse(item['created_at']?.toString() ?? '') ??
                DateTime.now(),
          );
        } else {
          await _gateway.upsert(table, payload);
        }
        await _store.removeOutbox(id);
        await _store.markSynced(table, entityId);
      } catch (error) {
        await _store.enqueueOutbox({
          ...item,
          'attempts': (item['attempts'] as int? ?? 0) + 1,
          'last_error': error.toString(),
        });
        rethrow;
      }
    }
  }

  bool _isOffline(List<ConnectivityResult> results) =>
      results.isEmpty || results.contains(ConnectivityResult.none);

  void _setStatus(SyncStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  Future<void> dispose() async {
    _disposed = true;
    _syncDebounce?.cancel();
    _pullDebounce?.cancel();
    await _connectivitySubscription?.cancel();
    await _authSubscription?.cancel();
    await _pendingSubscription?.cancel();
    await _changeSubscription?.cancel();
    await _inboxSubscription?.cancel();
    await _statusController.close();
    await _incomingTitipanController.close();
  }
}
