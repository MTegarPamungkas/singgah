import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/mappers/entity_mappers.dart';
import 'package:singgah/data/repositories/local_repository_base.dart';
import 'package:singgah/data/sync/sync_engine.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/repositories/mission_repository.dart';

class MissionRepositoryImpl extends LocalRepositoryBase
    implements MissionRepository {
  MissionRepositoryImpl(LocalStore store, SyncEngine sync, AuthRepository auth)
    : super(store, sync, auth);

  @override
  Stream<List<SinggahMission>> watchMissions() {
    return Stream.multi((controller) {
      void emit(List<Map<String, dynamic>> rows) {
        final missions =
            rows
                .map(missionFromRow)
                .where((mission) => !mission.isDeleted)
                .toList()
              ..sort((a, b) {
                if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
                final byCreated = (b.createdAt ?? DateTime(0)).compareTo(
                  a.createdAt ?? DateTime(0),
                );
                if (byCreated != 0) return byCreated;
                return a.title.toLowerCase().compareTo(b.title.toLowerCase());
              });
        if (!controller.isClosed) controller.add(missions);
      }

      emit(store.all('missions'));
      final subscription = store.watch('missions').listen(emit);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<List<SinggahMission>> getMissions() async => store
      .all('missions')
      .map(missionFromRow)
      .where((mission) => !mission.isDeleted)
      .toList();

  @override
  Future<SinggahMission?> getMission(String id) async {
    final row = store.get('missions', id);
    if (row == null) return null;
    final mission = missionFromRow(row);
    return mission.isDeleted ? null : mission;
  }

  @override
  Future<void> saveMission(SinggahMission mission) async {
    final now = DateTime.now();
    final payload = missionToRow(
      SinggahMission(
        id: mission.id,
        ownerId: userId,
        placeId: mission.placeId,
        title: mission.title.trim(),
        note: mission.note.trim(),
        trigger: mission.trigger,
        repeatDays: mission.repeatDays,
        windowStartMinutes: mission.windowStartMinutes,
        windowEndMinutes: mission.windowEndMinutes,
        isActive: mission.isActive,
        lastTriggeredAt: mission.lastTriggeredAt,
        createdAt: mission.createdAt ?? now,
        updatedAt: now,
      ),
    );
    await upsertRow('missions', payload, updatedAt: now);
  }

  @override
  Future<void> deleteMission(String id) => softDeleteRow('missions', id);

  @override
  Future<void> setAllActive(bool active) async {
    final missions = await getMissions();
    for (final mission in missions) {
      if (mission.isActive == active) continue;
      await saveMission(mission.copyWith(isActive: active));
    }
  }

  @override
  Future<void> markTriggered(String id, DateTime at) async {
    final mission = await getMission(id);
    if (mission == null) return;
    await saveMission(mission.copyWith(lastTriggeredAt: at));
  }
}
