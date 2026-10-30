import 'dart:async';
import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

/// Local source of truth. Every repository reads from here first so the app
/// remains fully usable without a network connection.
class LocalStore {
  static const List<String> dataTables = [
    'places',
    'missions',
    'titipan',
    'titipan_recipients',
    'singgah_events',
    'profiles',
  ];

  static const String ownerMetaKey = 'local_owner_id';

  final Map<String, Box<String>> _boxes = {};
  late Box<dynamic> _meta;
  late Box<String> _outbox;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init({String? directory, String name = 'singgah'}) async {
    if (_initialized) return;
    if (directory == null) {
      await Hive.initFlutter(name);
    } else {
      Hive.init(directory);
    }

    _meta = await Hive.openBox<dynamic>('meta');
    for (final table in dataTables) {
      _boxes[table] = await Hive.openBox<String>(table);
    }
    _outbox = await Hive.openBox<String>('outbox');
    _initialized = true;
  }

  Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }

  Box<String> _box(String table) {
    final box = _boxes[table];
    if (box == null) throw StateError('Unknown local table: $table');
    return box;
  }

  Map<String, dynamic>? get(String table, String id) {
    final raw = _box(table).get(id);
    if (raw == null) return null;
    return _decode(raw);
  }

  List<Map<String, dynamic>> all(String table) {
    final result = <Map<String, dynamic>>[];
    for (final raw in _box(table).values) {
      final decoded = _decode(raw);
      if (decoded != null) result.add(decoded);
    }
    return result;
  }

  Stream<List<Map<String, dynamic>>> watch(String table) {
    final box = _box(table);

    List<Map<String, dynamic>> read() {
      final result = <Map<String, dynamic>>[];
      for (final raw in box.values) {
        final decoded = _decode(raw);
        if (decoded != null) result.add(decoded);
      }
      return result;
    }

    return Stream.multi((controller) {
      controller.add(read());
      final subscription = box.watch().listen((_) => controller.add(read()));
      controller.onCancel = subscription.cancel;
    });
  }

  Future<void> put(
    String table,
    Map<String, dynamic> row, {
    bool pending = false,
  }) async {
    final payload = Map<String, dynamic>.from(row);
    if (pending) {
      payload['is_pending'] = true;
    } else {
      payload.remove('is_pending');
    }
    await _box(table).put(row['id'] as String, jsonEncode(payload));
  }

  Future<void> putMany(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _box(table)
        .putAll({for (final row in rows) row['id'] as String: jsonEncode(row)});
  }

  Future<void> delete(String table, String id) => _box(table).delete(id);

  Future<void> clearTable(String table) => _box(table).clear();

  Future<void> clearAllData() async {
    for (final table in dataTables) {
      await _box(table).clear();
    }
    await _outbox.clear();
    await _meta.clear();
  }

  /// Clears user-scoped data on sign-out while keeping device preferences.
  Future<void> clearUserData() async {
    for (final table in dataTables) {
      await _box(table).clear();
    }
    await _outbox.clear();

    final keys = _meta.keys.map((key) => key.toString()).toList();
    for (final key in keys) {
      if (key.startsWith('sync_cursor_') ||
          key.startsWith('geofence_plan_') ||
          key.startsWith('notified_titipan_') ||
          key == 'push_token' ||
          key == ownerMetaKey ||
          key == 'demo_user' ||
          key == 'seed_version') {
        await _meta.delete(key);
      }
    }
  }

  /// Prevents cached rows from leaking between two accounts on one device.
  Future<void> ensureUserScope(
    String userId, {
    bool discardDemoData = false,
  }) async {
    final owner = getMeta(ownerMetaKey);
    if (owner == userId) return;
    final hadDemo = getMeta('demo_user') != null;
    if (owner != null || (discardDemoData && hadDemo)) {
      await clearUserData();
    }
    await setMeta(ownerMetaKey, userId);
  }

  Future<void> markSynced(String table, String id) async {
    final row = get(table, id);
    if (row == null) return;
    row.remove('is_pending');
    await put(table, row);
  }

  dynamic getMeta(String key) => _meta.get(key);

  Future<void> setMeta(String key, dynamic value) => _meta.put(key, value);

  Future<void> removeMeta(String key) => _meta.delete(key);

  Stream<void> watchMeta(String key) => _meta.watch(key: key).map((_) {});

  Future<void> enqueueOutbox(Map<String, dynamic> item) async {
    await _outbox.put(item['id'] as String, jsonEncode(item));
  }

  List<Map<String, dynamic>> outboxItems() {
    final items = <Map<String, dynamic>>[];
    for (final raw in _outbox.values) {
      final decoded = _decode(raw);
      if (decoded != null) items.add(decoded);
    }
    items.sort(
      (a, b) => (a['created_at'] as String? ?? '').compareTo(
        b['created_at'] as String? ?? '',
      ),
    );
    return items;
  }

  Future<void> removeOutbox(String id) => _outbox.delete(id);

  Future<void> clearOutbox() => _outbox.clear();

  Stream<int> watchOutboxCount() {
    return Stream.multi((controller) {
      controller.add(_outbox.length);
      final subscription = _outbox.watch().listen(
        (_) => controller.add(_outbox.length),
      );
      controller.onCancel = subscription.cancel;
    });
  }

  Map<String, dynamic>? _decode(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    } on FormatException {
      return null;
    }
  }
}
