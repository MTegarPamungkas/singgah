import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:singgah/domain/entities/app_user.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';
import 'package:singgah/features/missions/presentation/bloc/mission_form_bloc.dart';

import '../helpers/bloc_settle.dart';

class MockGetMission extends Mock implements GetMission {}

class MockGetPlaces extends Mock implements GetPlaces {}

class MockSaveMission extends Mock implements SaveMission {}

class MockDeleteMission extends Mock implements DeleteMission {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockGetMission getMission;
  late MockGetPlaces getPlaces;
  late MockSaveMission saveMission;
  late MockDeleteMission deleteMission;
  late MockAuthRepository auth;

  final place = const Titik(
    id: 'p1',
    ownerId: 'u1',
    name: 'Kantor',
    latitude: -6.2,
    longitude: 106.8,
  );
  const user = AppUser(id: 'u1', email: 'a@b.c', displayName: 'Ayu');

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

  setUp(() {
    getMission = MockGetMission();
    getPlaces = MockGetPlaces();
    saveMission = MockSaveMission();
    deleteMission = MockDeleteMission();
    auth = MockAuthRepository();
    when(() => getPlaces()).thenAnswer((_) async => [place]);
    when(() => auth.currentUser).thenReturn(user);
    when(() => saveMission(any())).thenAnswer((_) async {});
    when(() => deleteMission(any())).thenAnswer((_) async {});
  });

  MissionFormBloc build({MissionFormArgs args = const MissionFormArgs()}) {
    return MissionFormBloc(
      getMission: getMission,
      getPlaces: getPlaces,
      saveMission: saveMission,
      deleteMission: deleteMission,
      auth: auth,
      args: args,
    );
  }

  blocTest<MissionFormBloc, MissionFormState>(
    'saves a valid mission with the chosen place and schedule',
    build: build,
    act: (bloc) {
      bloc.setTitle('Kirim laporan pagi');
      bloc.setNote('Lampirkan ringkasan');
      bloc.setPlace('p1', 'Kantor');
      bloc.setWindow(8 * 60, 11 * 60);
      bloc.setTrigger(MissionTrigger.leave);
      bloc.save();
    },
    wait: const Duration(milliseconds: 30),
    verify: (_) {
      final captured =
          verify(() => saveMission(captureAny())).captured.single
              as SinggahMission;
      expect(captured.title, 'Kirim laporan pagi');
      expect(captured.placeId, 'p1');
      expect(captured.trigger, MissionTrigger.leave);
      expect(captured.windowStartMinutes, 8 * 60);
      expect(captured.windowEndMinutes, 11 * 60);
    },
  );

  test('requires a title before saving', () async {
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    bloc.save();
    await settleBloc();
    expect(bloc.state.failure, MissionFormFailure.titleRequired);
    verifyNever(() => saveMission(any()));
  });

  test('requires a place before saving', () async {
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    bloc.setTitle('Bawa charger');
    bloc.save();
    await settleBloc();
    expect(bloc.state.failure, MissionFormFailure.placeRequired);
    verifyNever(() => saveMission(any()));
  });

  test('rejects an empty time window', () async {
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    bloc.setTitle('Bawa charger');
    bloc.setPlace('p1', 'Kantor');
    bloc.setWindow(9 * 60, 9 * 60);
    bloc.save();
    await settleBloc();
    expect(bloc.state.failure, MissionFormFailure.windowInvalid);
  });

  test('loads an existing mission for editing', () async {
    when(() => getMission('m1')).thenAnswer(
      (_) async => const SinggahMission(
        id: 'm1',
        ownerId: 'u1',
        placeId: 'p1',
        title: 'Beli galon',
        note: 'Dua galon',
        windowStartMinutes: 16 * 60,
        windowEndMinutes: 21 * 60,
      ),
    );
    final bloc = build(args: const MissionFormArgs(missionId: 'm1'));
    addTearDown(bloc.close);
    await settleBloc();
    expect(bloc.state.editing, isTrue);
    expect(bloc.state.title, 'Beli galon');
    expect(bloc.state.placeName, 'Kantor');
    expect(bloc.state.windowStartMinutes, 16 * 60);
  });

  test('toggles and presets repeat days', () async {
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    bloc.selectWeekdays();
    await settleBloc();
    expect(bloc.state.repeatDays, {1, 2, 3, 4, 5});
    bloc.toggleDay(3);
    await settleBloc();
    expect(bloc.state.repeatDays.contains(3), isFalse);
    bloc.selectEveryDay();
    await settleBloc();
    expect(bloc.state.everyDay, isTrue);
  });

  test('reports a save failure without losing the editor state', () async {
    when(() => saveMission(any())).thenThrow(Exception('offline'));
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    bloc.setTitle('Bawa charger');
    bloc.setPlace('p1', 'Kantor');
    bloc.save();
    await settleBloc();
    expect(bloc.state.failure, MissionFormFailure.save);
    expect(bloc.state.title, 'Bawa charger');
  });
}
