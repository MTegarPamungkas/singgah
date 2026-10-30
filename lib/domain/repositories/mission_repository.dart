import 'package:singgah/domain/entities/singgah_mission.dart';

abstract interface class MissionRepository {
  Stream<List<SinggahMission>> watchMissions();

  Future<List<SinggahMission>> getMissions();

  Future<SinggahMission?> getMission(String id);

  Future<void> saveMission(SinggahMission mission);

  Future<void> deleteMission(String id);

  Future<void> setAllActive(bool active);

  Future<void> markTriggered(String id, DateTime at);
}
