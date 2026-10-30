import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/domain/entities/app_user.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/sync_status.dart';
import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/entities/titipan_feed.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/usecases/sync_usecases.dart';
import 'package:singgah/domain/usecases/titipan_usecases.dart';
import 'package:singgah/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:singgah/features/titipan/presentation/bloc/titipan_bloc.dart';
import 'package:singgah/features/titipan/presentation/pages/titipan_page.dart';

class MockWatchFeed extends Mock implements WatchTitipanFeed {}

class MockDeleteTitipan extends Mock implements DeleteTitipan {}

class MockMarkRead extends Mock implements MarkTitipanRead {}

class MockEnsureLink extends Mock implements EnsureTitipanInviteLink {}

class MockRefresh extends Mock implements RefreshTitipan {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockWatchSync extends Mock implements WatchSyncStatus {}

class MockSyncNow extends Mock implements SyncNow {}

void main() {
  testWidgets('lists received Notes with an unread badge', (tester) async {
    final watchFeed = MockWatchFeed();
    final auth = MockAuthRepository();
    final note = Titipan(
      id: 't1',
      senderId: 'friend',
      senderName: 'Rani',
      placeName: 'Alfamart dekat rumah',
      latitude: -6.26,
      longitude: 106.81,
      title: 'Jangan lupa kunci pintu',
      body: 'Kunci dari dalam ya.',
      trigger: MissionTrigger.arrive,
      createdAt: DateTime(2026, 10, 20),
    );
    final feed = TitipanFeed(
      titipans: [note],
      recipients: [
        TitipanRecipient(
          id: 'r1',
          titipanId: 't1',
          userId: 'u1',
          acceptedAt: DateTime(2026, 10, 21),
        ),
      ],
    );
    when(() => watchFeed()).thenAnswer((_) => Stream.value(feed));
    when(
      () => auth.currentUser,
    ).thenReturn(const AppUser(id: 'u1', email: 'a@b.c', displayName: 'Ayu'));

    final titipanBloc = TitipanBloc(
      watchFeed,
      MockDeleteTitipan(),
      MockMarkRead(),
      MockEnsureLink(),
      MockRefresh(),
      auth,
    );
    addTearDown(titipanBloc.close);

    final watchSync = MockWatchSync();
    when(
      () => watchSync(),
    ).thenAnswer((_) => Stream.value(const SyncStatus(phase: SyncPhase.demo)));
    final syncBloc = SyncBloc(watchSync, MockSyncNow());
    addTearDown(syncBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TitipanBloc>.value(value: titipanBloc),
          BlocProvider<SyncBloc>.value(value: syncBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const TitipanPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jangan lupa kunci pintu'), findsOneWidget);
    expect(find.text('Dari Rani'), findsOneWidget);
    expect(find.text('Baru'), findsOneWidget);
    expect(find.text('Alfamart dekat rumah'), findsOneWidget);
  });
}
