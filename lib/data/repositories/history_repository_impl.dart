import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/mappers/entity_mappers.dart';
import 'package:singgah/domain/entities/singgah_event.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/repositories/history_repository.dart';
import 'package:singgah/domain/services/geofencing_service.dart';
import 'package:uuid/uuid.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({
    required LocalStore store,
    required AuthRepository auth,
    required GeofencingService geofencing,
    Uuid? uuid,
  }) : _store = store,
       _auth = auth,
       _geofencing = geofencing,
       _uuid = uuid ?? const Uuid();

  final LocalStore _store;
  final AuthRepository _auth;
  final GeofencingService _geofencing;
  final Uuid _uuid;

  @override
  Stream<List<SinggahEvent>> watchEvents() {
    return Stream.multi((controller) {
      void emit(List<Map<String, dynamic>> rows) {
        final events = rows.map(eventFromRow).toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        if (!controller.isClosed) controller.add(events);
      }

      emit(_store.all('singgah_events'));
      final subscription = _store.watch('singgah_events').listen(emit);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<List<SinggahEvent>> getEvents() async {
    final events = _store.all('singgah_events').map(eventFromRow).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return events;
  }

  @override
  Future<void> record(SinggahEvent event) async {
    if (_store.get('singgah_events', event.id) != null) return;
    final recent = _store
        .all('singgah_events')
        .map(eventFromRow)
        .any(
          (existing) =>
              existing.dedupeKey == event.dedupeKey &&
              existing.occurredAt.difference(event.occurredAt).abs() <
                  const Duration(minutes: 5),
        );
    if (recent) return;
    await _store.put('singgah_events', eventToRow(event));
  }

  @override
  Future<void> clear() => _store.clearTable('singgah_events');

  @override
  Future<int> drainNativeTransitions() async {
    if (!_geofencing.isSupported) return 0;
    final transitions = await _geofencing.drainTransitions();
    if (transitions.isEmpty) return 0;
    var recorded = 0;
    final owner = _auth.currentUser?.id ?? '';
    for (final transition in transitions) {
      final placeName = transition.placeName?.trim().isNotEmpty == true
          ? transition.placeName!
          : transition.title.replaceFirst('Singgah · ', '');
      final event = SinggahEvent(
        id: _uuid.v4(),
        ownerId: owner,
        placeId: transition.placeId,
        placeName: placeName,
        missionId: transition.missionId,
        titipanId: transition.titipanId,
        trigger: transition.transition,
        occurredAt: transition.occurredAt,
        source: SinggahEventSource.geofence,
      );
      await record(event);
      recorded++;
    }
    return recorded;
  }
}
