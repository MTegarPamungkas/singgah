import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/domain/entities/app_user.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';
import 'package:singgah/features/missions/presentation/bloc/mission_form_bloc.dart';
import 'package:singgah/features/missions/presentation/pages/mission_form_page.dart';

class MockGetMission extends Mock implements GetMission {}

class MockGetPlaces extends Mock implements GetPlaces {}

class MockSaveMission extends Mock implements SaveMission {}

class MockDeleteMission extends Mock implements DeleteMission {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const SinggahMission(
        id: 'fallback',
        ownerId: 'owner',
        placeId: 'place',
        title: 'fallback',
      ),
    );
  });

  testWidgets('creates a reminder from the mission editor', (tester) async {
    final getMission = MockGetMission();
    final getPlaces = MockGetPlaces();
    final saveMission = MockSaveMission();
    final deleteMission = MockDeleteMission();
    final auth = MockAuthRepository();
    when(() => getPlaces()).thenAnswer(
      (_) async => const [
        Titik(
          id: 'p1',
          ownerId: 'u1',
          name: 'Kantor',
          latitude: -6.2,
          longitude: 106.8,
        ),
      ],
    );
    when(
      () => auth.currentUser,
    ).thenReturn(const AppUser(id: 'u1', email: 'a@b.c', displayName: 'Ayu'));
    when(() => saveMission(any())).thenAnswer((_) async {});
    when(() => deleteMission(any())).thenAnswer((_) async {});

    final bloc = MissionFormBloc(
      getMission: getMission,
      getPlaces: getPlaces,
      saveMission: saveMission,
      deleteMission: deleteMission,
      auth: auth,
      args: const MissionFormArgs(),
    );
    addTearDown(bloc.close);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('HOME'),
                  TextButton(
                    onPressed: () => context.push('/mission'),
                    child: const Text('OPEN MISSION'),
                  ),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/mission',
          builder: (context, state) =>
              BlocProvider.value(value: bloc, child: const MissionFormPage()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        locale: const Locale('id'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN MISSION'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Kirim laporan');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kantor').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan Misi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Misi'));
    await tester.pumpAndSettle();

    verify(() => saveMission(any())).called(1);
    expect(find.text('HOME'), findsOneWidget);
  });
}
