import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/mappers/entity_mappers.dart';
import 'package:singgah/data/repositories/local_repository_base.dart';
import 'package:singgah/data/sync/sync_engine.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/repositories/place_repository.dart';

class PlaceRepositoryImpl extends LocalRepositoryBase
    implements PlaceRepository {
  PlaceRepositoryImpl(LocalStore store, SyncEngine sync, AuthRepository auth)
    : super(store, sync, auth);

  @override
  Stream<List<Titik>> watchPlaces() {
    // Emit a snapshot immediately so screens do not flash an empty state while
    // Hive warms up.
    return Stream.multi((controller) {
      void emit(List<Map<String, dynamic>> rows) {
        final places =
            rows
                .map(titikFromRow)
                .where((place) => !place.isDeleted && place.hasValidCoordinates)
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
        if (!controller.isClosed) controller.add(places);
      }

      emit(store.all('places'));
      final subscription = store.watch('places').listen(emit);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<List<Titik>> getPlaces() async =>
      store.all('places').map(titikFromRow).where((p) => !p.isDeleted).toList();

  @override
  Future<Titik?> getPlace(String id) async {
    final row = store.get('places', id);
    if (row == null) return null;
    final place = titikFromRow(row);
    return place.isDeleted ? null : place;
  }

  @override
  Future<void> savePlace(Titik place) async {
    final now = DateTime.now();
    final payload = titikToRow(
      Titik(
        id: place.id,
        ownerId: userId,
        name: place.name.trim(),
        address: place.address.trim(),
        latitude: place.latitude,
        longitude: place.longitude,
        radiusMeters: place.radiusMeters.clamp(100, 2000),
        iconKey: place.iconKey,
        colorHex: place.colorHex,
        createdAt: place.createdAt ?? now,
        updatedAt: now,
      ),
    );
    await upsertRow('places', payload, updatedAt: now);
  }

  @override
  Future<void> deletePlace(String id) => softDeleteRow('places', id);
}
