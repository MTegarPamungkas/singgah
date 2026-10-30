import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:singgah/domain/entities/app_user.dart';
import 'package:singgah/domain/entities/natural_draft.dart';
import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';
import 'package:singgah/domain/usecases/discovery_usecases.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';
import 'package:singgah/features/natural/presentation/bloc/natural_bloc.dart';

import '../helpers/bloc_settle.dart';

class MockParseNatural extends Mock implements ParseNaturalReminder {}

class MockWatchPlaces extends Mock implements WatchPlaces {}

class MockSavePlace extends Mock implements SavePlace {}

class MockSaveMission extends Mock implements SaveMission {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockParseNatural parse;
  late MockWatchPlaces watchPlaces;
  late MockSavePlace savePlace;
  late MockSaveMission saveMission;
  late MockAuthRepository auth;

  const place = Titik(
    id: 'p1',
    ownerId: 'u1',
    name: 'Alfamart',
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
    registerFallbackValue(
      const Titik(
        id: 'fallback',
        ownerId: 'owner',
        name: 'Fallback',
        latitude: 0,
        longitude: 0,
      ),
    );
  });

  setUp(() {
    parse = MockParseNatural();
    watchPlaces = MockWatchPlaces();
    savePlace = MockSavePlace();
    saveMission = MockSaveMission();
    auth = MockAuthRepository();
    when(() => watchPlaces()).thenAnswer((_) => Stream.value([place]));
    when(() => auth.currentUser).thenReturn(user);
    when(() => savePlace(any())).thenAnswer((_) async {});
    when(() => saveMission(any())).thenAnswer((_) async {});
    when(() => parse(any(), localeCode: any(named: 'localeCode'))).thenAnswer(
      (_) async => const NaturalDraft(
        rawText: 'beli galon pas lewat Alfamart',
        title: 'Beli galon',
        placeName: 'Alfamart',
        confidence: 0.8,
      ),
    );
  });

  NaturalBloc build() => NaturalBloc(
    parse: parse,
    watchPlaces: watchPlaces,
    savePlace: savePlace,
    saveMission: saveMission,
    auth: auth,
  );

  test('parses text and matches a saved place', () async {
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    bloc.setText('beli galon pas lewat Alfamart');
    bloc.parse();
    await settleBloc();
    expect(bloc.state.draft!.title, 'Beli galon');
    expect(bloc.state.selectedPlace?.id, 'p1');
    expect(bloc.state.failure, isNull);
  });

  test('rejects empty and over-long input', () async {
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    bloc.parse();
    await settleBloc();
    expect(bloc.state.failure, NaturalFailure.empty);
    bloc.clearFailure();
    bloc.setText('a' * 501);
    bloc.parse();
    await settleBloc();
    expect(bloc.state.failure, NaturalFailure.tooLong);
    verifyNever(() => parse(any(), localeCode: any(named: 'localeCode')));
  });

  test('surfaces rate limiting from the backend', () async {
    when(() => parse(any(), localeCode: any(named: 'localeCode')))
        .thenThrow(const DiscoveryException('limit', rateLimited: true));
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    bloc.setText('beli galon');
    bloc.parse();
    await settleBloc();
    expect(bloc.state.failure, NaturalFailure.rateLimited);
  });

  test('refuses to save without a recognisable place', () async {
    when(() => parse(any(), localeCode: any(named: 'localeCode'))).thenAnswer(
      (_) async => const NaturalDraft(
        rawText: 'beli galon',
        title: 'Beli galon',
        placeName: 'Tempat misterius',
      ),
    );
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    bloc.setText('beli galon');
    bloc.parse();
    await settleBloc();
    expect(bloc.state.draft, isNotNull);
    bloc.save();
    await settleBloc();
    expect(bloc.state.failure, NaturalFailure.noPlace);
    verifyNever(() => saveMission(any()));
  });

  test('saves a new place and mission when a suggestion is chosen', () async {
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    bloc.setText('beli galon');
    bloc.parse();
    await settleBloc();
    bloc.selectSuggestion(
      const PlaceSuggestion(
        name: 'Toko Baru',
        address: 'Jl. Baru',
        latitude: -6.3,
        longitude: 106.9,
      ),
    );
    await settleBloc();
    bloc.save();
    await settleBloc();
    expect(bloc.state.saved, isTrue);
    verify(() => savePlace(any())).called(1);
    verify(() => saveMission(any())).called(1);
  });
}
