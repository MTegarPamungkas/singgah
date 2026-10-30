import 'package:singgah/domain/entities/app_settings.dart';
import 'package:singgah/domain/repositories/settings_repository.dart';

class WatchSettings {
  const WatchSettings(this._repository);
  final SettingsRepository _repository;

  Stream<AppSettings> call() => _repository.watchSettings();
}

class GetSettings {
  const GetSettings(this._repository);
  final SettingsRepository _repository;

  Future<AppSettings> call() => _repository.getSettings();
}

class UpdateSettings {
  const UpdateSettings(this._repository);
  final SettingsRepository _repository;

  Future<void> call(AppSettings settings) =>
      _repository.updateSettings(settings);
}
