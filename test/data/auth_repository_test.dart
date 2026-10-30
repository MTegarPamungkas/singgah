import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/repositories/auth_repository_impl.dart';
import 'package:singgah/data/seed/demo_seeder.dart';

void main() {
  late Directory directory;
  late LocalStore store;
  late AuthRepositoryImpl auth;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('singgah_test_');
    store = LocalStore();
    await store.init(directory: directory.path, name: 'singgah_test');
    auth = AuthRepositoryImpl(store: store, seeder: DemoSeeder(store));
  });

  tearDown(() async {
    await store.close();
    await directory.delete(recursive: true);
  });

  test('demo sign-in seeds a scoped, local sample workspace', () async {
    expect(auth.isDemo, isTrue);
    expect(auth.currentUser, isNull);

    final user = await auth.continueAsDemo();
    expect(user.id, AppConfig.demoUserId);
    expect(user.isDemo, isTrue);
    expect(auth.currentUser?.displayName, AppConfig.demoName);
    expect(store.getMeta(LocalStore.ownerMetaKey), AppConfig.demoUserId);

    expect(store.all('places'), hasLength(3));
    expect(store.all('missions'), hasLength(3));
    expect(store.all('titipan'), hasLength(1));
    expect(store.all('titipan_recipients'), hasLength(1));

    await auth.signOut();
    expect(auth.currentUser, isNull);
    expect(store.all('places'), isEmpty);
    expect(store.all('missions'), isEmpty);
    expect(store.all('titipan'), isEmpty);
    expect(store.outboxItems(), isEmpty);
  });

  test('scope changes clear another account\'s cached rows', () async {
    await store.setMeta(LocalStore.ownerMetaKey, 'old-user');
    await store.put('places', {
      'id': 'p1',
      'owner_id': 'old-user',
      'name': 'Old place',
      'latitude': 0,
      'longitude': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await store.ensureUserScope('new-user');
    expect(store.all('places'), isEmpty);
    expect(store.getMeta(LocalStore.ownerMetaKey), 'new-user');
  });
}
