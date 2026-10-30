import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/domain/entities/app_settings.dart';
import 'package:singgah/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._store);

  final LocalStore _store;

  static const String _key = 'settings';

  @override
  Stream<AppSettings> watchSettings() {
    return Stream.multi((controller) {
      void emit() {
        if (!controller.isClosed) controller.add(_read());
      }

      emit();
      final subscription = _store.watchMeta(_key).listen((_) => emit());
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<AppSettings> getSettings() async => _read();

  @override
  Future<void> updateSettings(AppSettings settings) async {
    await _store.setMeta(_key, settings.toMap());
  }

  AppSettings _read() {
    final value = _store.getMeta(_key);
    if (value is Map) {
      return AppSettings.fromMap(Map<String, dynamic>.from(value));
    }
    return const AppSettings();
  }
}
