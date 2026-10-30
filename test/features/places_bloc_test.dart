import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:singgah/domain/entities/singgah_mission.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';
import 'package:singgah/features/places/presentation/bloc/places_bloc.dart';

import '../helpers/bloc_settle.dart';

class MockWatchPlaces extends Mock implements WatchPlaces {}

class MockWatchMissions extends Mock implements WatchMissions {}

class MockDeletePlace extends Mock implements DeletePlace {}

void main() {
  late MockWatchPlaces watchPlaces;
  late MockWatchMissions watchMissions;
  late MockDeletePlace deletePlace;

  const home = Titik(
    id: 'p1',
    ownerId: 'u1',
    name: 'Rumah',
    latitude: -6.2,
    longitude: 106.8,
  );
  const mission = SinggahMission(
    id: 'm1',
    ownerId: 'u1',
    placeId: 'p1',
    title: 'Bawa charger',
  );

  setUp(() {
    watchPlaces = MockWatchPlaces();
    watchMissions = MockWatchMissions();
    deletePlace = MockDeletePlace();
    when(() => watchPlaces()).thenAnswer((_) => Stream.value([home]));
    when(() => watchMissions()).thenAnswer((_) => Stream.value([mission]));
    when(() => deletePlace(any())).thenAnswer((_) async {});
  });

  PlacesBloc build() => PlacesBloc(watchPlaces, watchMissions, deletePlace);

  test('combines places with mission counts', () async {
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    expect(bloc.state.places.single.name, 'Rumah');
    expect(bloc.state.missionCounts['p1'], 1);
    expect(bloc.state.totalMissions, 1);
  });

  test('delete reports success and failure', () async {
    final bloc = build();
    addTearDown(bloc.close);
    await settleBloc();
    expect(await bloc.deletePlace('p1'), isTrue);
    verify(() => deletePlace('p1')).called(1);

    when(() => deletePlace('p2')).thenThrow(Exception('denied'));
    expect(await bloc.deletePlace('p2'), isFalse);
    expect(bloc.state.failure, PlacesFailure.delete);
    expect(bloc.state.deleting, isFalse);
  });
}
