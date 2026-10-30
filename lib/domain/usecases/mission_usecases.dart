import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/repositories/mission_repository.dart';

class WatchMissions {
  const WatchMissions(this._repository);
  final MissionRepository _repository;

  Stream<List<SinggahMission>> call() => _repository.watchMissions();
}

class GetMissions {
  const GetMissions(this._repository);
  final MissionRepository _repository;

  Future<List<SinggahMission>> call() => _repository.getMissions();
}

class GetMission {
  const GetMission(this._repository);
  final MissionRepository _repository;

  Future<SinggahMission?> call(String id) => _repository.getMission(id);
}

class SaveMission {
  const SaveMission(this._repository);
  final MissionRepository _repository;

  Future<void> call(SinggahMission mission) => _repository.saveMission(mission);
}

class DeleteMission {
  const DeleteMission(this._repository);
  final MissionRepository _repository;

  Future<void> call(String id) => _repository.deleteMission(id);
}

class SetAllMissionsActive {
  const SetAllMissionsActive(this._repository);
  final MissionRepository _repository;

  Future<void> call(bool active) => _repository.setAllActive(active);
}

class MarkMissionTriggered {
  const MarkMissionTriggered(this._repository);
  final MissionRepository _repository;

  Future<void> call(String id, DateTime at) =>
      _repository.markTriggered(id, at);
}
