import 'package:singgah/domain/entities/app_settings.dart';

abstract interface class SettingsRepository {
  Stream<AppSettings> watchSettings();

  Future<AppSettings> getSettings();

  Future<void> updateSettings(AppSettings settings);
}
