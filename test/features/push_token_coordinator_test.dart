import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/services/push_token_coordinator.dart';
import 'package:singgah/domain/entities/app_user.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/services/push_notification_service.dart';

import '../helpers/bloc_settle.dart';

class MockAuth extends Mock implements AuthRepository {}

class MockGateway extends Mock implements CloudGateway {}

class MockPush extends Mock implements PushNotificationService {}

class MockStore extends Mock implements LocalStore {}

void main() {
  late MockAuth auth;
  late MockGateway gateway;
  late MockPush push;
  late MockStore store;
  late StreamController<AppUser?> users;
  late StreamController<String> refreshes;

  const user = AppUser(id: 'u1', email: 'a@b.c', displayName: 'Ayu');

  setUp(() {
    auth = MockAuth();
    gateway = MockGateway();
    push = MockPush();
    store = MockStore();
    users = StreamController<AppUser?>.broadcast();
    refreshes = StreamController<String>.broadcast();
    when(() => auth.currentUser).thenReturn(user);
    when(() => auth.watchUser()).thenAnswer((_) => users.stream);
    when(() => push.isConfigured).thenReturn(true);
    when(() => push.tokenRefreshes).thenAnswer((_) => refreshes.stream);
    when(() => push.initializeAndGetToken())
        .thenAnswer((_) async => 'fcm-token-123456');
    when(() => push.dispose()).thenAnswer((_) async {});
    when(() => store.getMeta(any())).thenReturn(null);
    when(() => store.setMeta(any(), any())).thenAnswer((_) async {});
    when(() => store.removeMeta(any())).thenAnswer((_) async {});
    when(() => gateway.registerDeviceToken(any(), any()))
        .thenAnswer((_) async {});
    when(() => gateway.unregisterDeviceToken(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await users.close();
    await refreshes.close();
  });

  test('registers the token for the signed-in account', () async {
    final coordinator = PushTokenCoordinator(
      store: store,
      auth: auth,
      gateway: gateway,
      push: push,
    );
    addTearDown(coordinator.dispose);
    await coordinator.start();
    await settleBloc();
    verify(() => gateway.registerDeviceToken('fcm-token-123456', 'android'))
        .called(1);
  });

  test('reassigns on token refresh and removes it on sign-out', () async {
    final coordinator = PushTokenCoordinator(
      store: store,
      auth: auth,
      gateway: gateway,
      push: push,
    );
    addTearDown(coordinator.dispose);
    await coordinator.start();
    await settleBloc();
    refreshes.add('fcm-token-rotated');
    await settleBloc();
    verify(() => gateway.registerDeviceToken('fcm-token-rotated', 'android'))
        .called(1);

    users.add(null);
    await settleBloc();
    verify(() => gateway.unregisterDeviceToken('fcm-token-rotated')).called(1);
  });

  test('does nothing when Firebase is not configured', () async {
    when(() => push.isConfigured).thenReturn(false);
    final coordinator = PushTokenCoordinator(
      store: store,
      auth: auth,
      gateway: gateway,
      push: push,
    );
    addTearDown(coordinator.dispose);
    await coordinator.start();
    await settleBloc();
    verifyNever(() => push.initializeAndGetToken());
    verifyNever(() => gateway.registerDeviceToken(any(), any()));
  });
}
