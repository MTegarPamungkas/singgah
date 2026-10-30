import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/mappers/entity_mappers.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/entities/titipan.dart';
import 'package:uuid/uuid.dart';

/// Seeds a small, believable set of rows in demo mode. Cloud sessions never
/// see this data because sign-in discards demo-scoped rows.
class DemoSeeder {
  DemoSeeder(this._store, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final LocalStore _store;
  final Uuid _uuid;

  static const int seedVersion = 1;

  Future<void> seedIfNeeded() async {
    final current = _store.getMeta('seed_version');
    if (current is int && current >= seedVersion) return;

    final now = DateTime.now().toUtc();
    final homeId = _uuid.v4();
    final officeId = _uuid.v4();
    final shopId = _uuid.v4();

    final home = _place(
      id: homeId,
      name: 'Rumah',
      address: 'Jl. Bangka Raya No. 8, Jakarta Selatan',
      latitude: -6.2433,
      longitude: 106.8178,
      icon: 'home',
      now: now,
    );
    final office = _place(
      id: officeId,
      name: 'Kantor',
      address: 'Jl. Jend. Sudirman Kav. 52, Jakarta Selatan',
      latitude: -6.2247,
      longitude: 106.8085,
      icon: 'work',
      now: now,
    );
    final shop = _place(
      id: shopId,
      name: 'Alfamart dekat rumah',
      address: 'Jl. Kemang Raya No. 12, Jakarta Selatan',
      latitude: -6.2607,
      longitude: 106.8132,
      icon: 'store',
      now: now,
    );

    for (final place in [home, office, shop]) {
      await _store.put('places', titikToRow(place));
    }

    final missions = [
      SinggahMission(
        id: _uuid.v4(),
        ownerId: AppConfig.demoUserId,
        placeId: homeId,
        title: 'Bawa charger',
        note: 'Charger ada di meja dekat jendela.',
        trigger: MissionTrigger.leave,
        repeatDays: const {1, 2, 3, 4, 5},
        windowStartMinutes: 7 * 60,
        windowEndMinutes: 9 * 60,
        createdAt: now,
        updatedAt: now,
      ),
      SinggahMission(
        id: _uuid.v4(),
        ownerId: AppConfig.demoUserId,
        placeId: officeId,
        title: 'Kirim laporan pagi',
        note: 'Lampirkan ringkasan harian ke tim.',
        trigger: MissionTrigger.arrive,
        repeatDays: const {1, 2, 3, 4, 5},
        windowStartMinutes: 8 * 60,
        windowEndMinutes: 11 * 60,
        createdAt: now,
        updatedAt: now,
      ),
      SinggahMission(
        id: _uuid.v4(),
        ownerId: AppConfig.demoUserId,
        placeId: shopId,
        title: 'Beli galon',
        note: 'Ambil dua galon kalau stok ada.',
        trigger: MissionTrigger.arrive,
        windowStartMinutes: 16 * 60,
        windowEndMinutes: 21 * 60,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final mission in missions) {
      await _store.put('missions', missionToRow(mission));
    }

    final titipan = Titipan(
      id: _uuid.v4(),
      senderId: 'demo-sender-rani',
      senderName: 'Rani',
      placeId: shopId,
      placeName: 'Alfamart dekat rumah',
      latitude: -6.2607,
      longitude: 106.8132,
      title: 'Ambil pesanan yang dititipkan',
      body: 'Paket kecil ada di kasir. Sebut nama Rani ya.',
      trigger: MissionTrigger.arrive,
      inviteToken: 'demo-invite-rani',
      recipientHint: 'Demo',
      createdAt: now,
      updatedAt: now,
    );
    await _store.put('titipan', titipanToRow(titipan));
    await _store.put(
      'titipan_recipients',
      recipientToRow(
        TitipanRecipient(
          id: _uuid.v4(),
          titipanId: titipan.id,
          userId: AppConfig.demoUserId,
          acceptedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );

    await _store.setMeta('seed_version', seedVersion);
  }

  Titik _place({
    required String id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required String icon,
    required DateTime now,
  }) {
    return Titik(
      id: id,
      ownerId: AppConfig.demoUserId,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: 150,
      iconKey: icon,
      createdAt: now,
      updatedAt: now,
    );
  }
}
