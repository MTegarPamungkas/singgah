import 'package:appwrite/appwrite.dart' as aw;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import 'package:singgah/app/app_maintenance.dart';
import 'package:singgah/data/datasources/appwrite_cloud_gateway.dart';
import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/data/datasources/demo_cloud_gateway.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/repositories/auth_repository_impl.dart';
import 'package:singgah/data/repositories/discovery_repository_impl.dart';
import 'package:singgah/data/repositories/history_repository_impl.dart';
import 'package:singgah/data/repositories/mission_repository_impl.dart';
import 'package:singgah/data/repositories/place_repository_impl.dart';
import 'package:singgah/data/repositories/settings_repository_impl.dart';
import 'package:singgah/data/repositories/titipan_repository_impl.dart';
import 'package:singgah/data/seed/demo_seeder.dart';
import 'package:singgah/data/services/biometric_service.dart';
import 'package:singgah/data/services/deep_link_service.dart';
import 'package:singgah/data/services/geofence_coordinator.dart';
import 'package:singgah/data/services/geofencing_service.dart';
import 'package:singgah/data/services/location_service.dart';
import 'package:singgah/data/services/notification_service.dart';
import 'package:singgah/data/services/push_notification_service.dart';
import 'package:singgah/data/services/push_token_coordinator.dart';
import 'package:singgah/data/services/titipan_notification_coordinator.dart';
import 'package:singgah/data/sync/sync_engine.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';
import 'package:singgah/domain/repositories/history_repository.dart';
import 'package:singgah/domain/repositories/mission_repository.dart';
import 'package:singgah/domain/repositories/place_repository.dart';
import 'package:singgah/domain/repositories/settings_repository.dart';
import 'package:singgah/domain/repositories/sync_repository.dart';
import 'package:singgah/domain/repositories/titipan_repository.dart';
import 'package:singgah/domain/services/biometric_service.dart' as domain;
import 'package:singgah/domain/services/deep_link_service.dart' as domain;
import 'package:singgah/domain/services/geofence_manager.dart';
import 'package:singgah/domain/services/geofencing_service.dart' as domain;
import 'package:singgah/domain/services/location_service.dart' as domain;
import 'package:singgah/domain/services/notification_service.dart' as domain;
import 'package:singgah/domain/services/push_notification_service.dart'
    as domain;
import 'package:singgah/domain/usecases/auth_usecases.dart';
import 'package:singgah/domain/usecases/device_usecases.dart';
import 'package:singgah/domain/usecases/discovery_usecases.dart';
import 'package:singgah/domain/usecases/history_usecases.dart';
import 'package:singgah/domain/usecases/mission_usecases.dart';
import 'package:singgah/domain/usecases/place_usecases.dart';
import 'package:singgah/domain/usecases/settings_usecases.dart';
import 'package:singgah/domain/usecases/sync_usecases.dart';
import 'package:singgah/domain/usecases/titipan_usecases.dart';
import 'package:singgah/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:singgah/features/history/presentation/bloc/history_bloc.dart';
import 'package:singgah/features/home/presentation/bloc/home_bloc.dart';
import 'package:singgah/features/missions/presentation/bloc/mission_form_bloc.dart';
import 'package:singgah/features/missions/presentation/bloc/missions_bloc.dart';
import 'package:singgah/features/natural/presentation/bloc/natural_bloc.dart';
import 'package:singgah/features/permissions/presentation/bloc/permissions_bloc.dart';
import 'package:singgah/features/places/presentation/bloc/place_form_bloc.dart';
import 'package:singgah/features/places/presentation/bloc/place_picker_bloc.dart';
import 'package:singgah/features/places/presentation/bloc/places_bloc.dart';
import 'package:singgah/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:singgah/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:singgah/features/titipan/presentation/bloc/invite_bloc.dart';
import 'package:singgah/features/titipan/presentation/bloc/titipan_bloc.dart';
import 'package:singgah/features/titipan/presentation/bloc/titipan_form_bloc.dart';

final GetIt getIt = GetIt.instance;

/// Wires the whole app once, at startup. Widgets and blocs only ever receive
/// interfaces, so demo mode and Appwrite share exactly the same code path.
Future<void> configureDependencies({
  required LocalStore store,
  aw.Client? appwriteClient,
}) async {
  getIt.registerSingleton<LocalStore>(store);
  getIt.registerLazySingleton<Uuid>(() => const Uuid());

  getIt.registerLazySingleton<CloudGateway>(
    () => appwriteClient == null
        ? DemoCloudGateway()
        : AppwriteCloudGateway(appwriteClient),
  );
  getIt.registerLazySingleton<DemoSeeder>(() => DemoSeeder(store));
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      store: store,
      seeder: getIt<DemoSeeder>(),
      client: appwriteClient,
      gateway: getIt<CloudGateway>(),
    ),
  );

  getIt.registerLazySingleton<Connectivity>(Connectivity.new);
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(store),
  );
  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      store: store,
      gateway: getIt<CloudGateway>(),
      auth: getIt<AuthRepository>(),
      connectivity: getIt<Connectivity>(),
    ),
  );
  getIt.registerLazySingleton<SyncRepository>(() => getIt<SyncEngine>());

  getIt.registerLazySingleton<PlaceRepository>(
    () => PlaceRepositoryImpl(
      store,
      getIt<SyncEngine>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerLazySingleton<MissionRepository>(
    () => MissionRepositoryImpl(
      store,
      getIt<SyncEngine>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerLazySingleton<TitipanRepository>(
    () => TitipanRepositoryImpl(
      store,
      getIt<SyncEngine>(),
      getIt<AuthRepository>(),
      getIt<CloudGateway>(),
    ),
  );
  getIt.registerLazySingleton<DiscoveryRepository>(
    () => DiscoveryRepositoryImpl(getIt<CloudGateway>()),
  );

  getIt.registerLazySingleton<domain.LocationService>(createLocationService);
  getIt.registerLazySingleton<domain.GeofencingService>(
    createGeofencingService,
  );
  getIt.registerLazySingleton<domain.NotificationService>(
    createNotificationService,
  );
  getIt.registerLazySingleton<domain.BiometricService>(createBiometricService);
  getIt.registerLazySingleton<domain.DeepLinkService>(createDeepLinkService);
  getIt.registerLazySingleton<domain.PushNotificationService>(
    createPushNotificationService,
  );

  getIt.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(
      store: store,
      auth: getIt<AuthRepository>(),
      geofencing: getIt<domain.GeofencingService>(),
    ),
  );
  getIt.registerLazySingleton<GeofenceCoordinator>(
    () => GeofenceCoordinator(
      store: store,
      auth: getIt<AuthRepository>(),
      places: getIt<PlaceRepository>(),
      missions: getIt<MissionRepository>(),
      titipan: getIt<TitipanRepository>(),
      settings: getIt<SettingsRepository>(),
      location: getIt<domain.LocationService>(),
      geofencing: getIt<domain.GeofencingService>(),
      history: getIt<HistoryRepository>(),
    ),
  );
  getIt.registerLazySingleton<GeofenceManager>(
    () => getIt<GeofenceCoordinator>(),
  );
  getIt.registerLazySingleton<TitipanNotificationCoordinator>(
    () => TitipanNotificationCoordinator(
      store: store,
      sync: getIt<SyncEngine>(),
      titipan: getIt<TitipanRepository>(),
      auth: getIt<AuthRepository>(),
      notifications: getIt<domain.NotificationService>(),
      push: getIt<domain.PushNotificationService>(),
    ),
  );
  getIt.registerLazySingleton<PushTokenCoordinator>(
    () => PushTokenCoordinator(
      store: store,
      auth: getIt<AuthRepository>(),
      gateway: getIt<CloudGateway>(),
      push: getIt<domain.PushNotificationService>(),
    ),
  );

  _registerUsecases();
  getIt.registerLazySingleton<AppMaintenance>(
    () => AppMaintenance(
      getIt<GeofenceCoordinator>(),
      getIt<domain.NotificationService>(),
      getIt<TitipanNotificationCoordinator>(),
      getIt<PushTokenCoordinator>(),
      getIt<SyncEngine>(),
    ),
  );
  _registerBlocs();
}

void _registerUsecases() {
  getIt.registerLazySingleton<WatchAuthUser>(
    () => WatchAuthUser(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<GetCurrentUser>(
    () => GetCurrentUser(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignInWithEmail>(
    () => SignInWithEmail(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignUpWithEmail>(
    () => SignUpWithEmail(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignInWithGoogle>(
    () => SignInWithGoogle(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<ContinueAsDemo>(
    () => ContinueAsDemo(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignOut>(() => SignOut(getIt<AuthRepository>()));
  getIt.registerLazySingleton<UpdateProfile>(
    () => UpdateProfile(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<UploadAvatar>(
    () => UploadAvatar(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<WatchPlaces>(
    () => WatchPlaces(getIt<PlaceRepository>()),
  );
  getIt.registerLazySingleton<GetPlaces>(
    () => GetPlaces(getIt<PlaceRepository>()),
  );
  getIt.registerLazySingleton<GetPlace>(
    () => GetPlace(getIt<PlaceRepository>()),
  );
  getIt.registerLazySingleton<SavePlace>(
    () => SavePlace(getIt<PlaceRepository>()),
  );
  getIt.registerLazySingleton<DeletePlace>(
    () => DeletePlace(getIt<PlaceRepository>()),
  );

  getIt.registerLazySingleton<WatchMissions>(
    () => WatchMissions(getIt<MissionRepository>()),
  );
  getIt.registerLazySingleton<GetMissions>(
    () => GetMissions(getIt<MissionRepository>()),
  );
  getIt.registerLazySingleton<GetMission>(
    () => GetMission(getIt<MissionRepository>()),
  );
  getIt.registerLazySingleton<SaveMission>(
    () => SaveMission(getIt<MissionRepository>()),
  );
  getIt.registerLazySingleton<DeleteMission>(
    () => DeleteMission(getIt<MissionRepository>()),
  );
  getIt.registerLazySingleton<SetAllMissionsActive>(
    () => SetAllMissionsActive(getIt<MissionRepository>()),
  );
  getIt.registerLazySingleton<MarkMissionTriggered>(
    () => MarkMissionTriggered(getIt<MissionRepository>()),
  );

  getIt.registerLazySingleton<WatchTitipanFeed>(
    () => WatchTitipanFeed(getIt<TitipanRepository>()),
  );
  getIt.registerLazySingleton<GetTitipanFeed>(
    () => GetTitipanFeed(getIt<TitipanRepository>()),
  );
  getIt.registerLazySingleton<GetTitipan>(
    () => GetTitipan(getIt<TitipanRepository>()),
  );
  getIt.registerLazySingleton<SaveTitipan>(
    () => SaveTitipan(getIt<TitipanRepository>()),
  );
  getIt.registerLazySingleton<DeleteTitipan>(
    () => DeleteTitipan(getIt<TitipanRepository>()),
  );
  getIt.registerLazySingleton<AcceptTitipanInvite>(
    () => AcceptTitipanInvite(getIt<TitipanRepository>()),
  );
  getIt.registerLazySingleton<EnsureTitipanInviteLink>(
    () => EnsureTitipanInviteLink(getIt<TitipanRepository>()),
  );
  getIt.registerLazySingleton<MarkTitipanRead>(
    () => MarkTitipanRead(getIt<TitipanRepository>()),
  );
  getIt.registerLazySingleton<RefreshTitipan>(
    () => RefreshTitipan(getIt<TitipanRepository>()),
  );

  getIt.registerLazySingleton<WatchHistory>(
    () => WatchHistory(getIt<HistoryRepository>()),
  );
  getIt.registerLazySingleton<RecordSinggahEvent>(
    () => RecordSinggahEvent(getIt<HistoryRepository>()),
  );
  getIt.registerLazySingleton<ClearHistory>(
    () => ClearHistory(getIt<HistoryRepository>()),
  );
  getIt.registerLazySingleton<DrainNativeTransitions>(
    () => DrainNativeTransitions(getIt<HistoryRepository>()),
  );

  getIt.registerLazySingleton<WatchSettings>(
    () => WatchSettings(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<GetSettings>(
    () => GetSettings(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<UpdateSettings>(
    () => UpdateSettings(getIt<SettingsRepository>()),
  );

  getIt.registerLazySingleton<ParseNaturalReminder>(
    () => ParseNaturalReminder(getIt<DiscoveryRepository>()),
  );
  getIt.registerLazySingleton<SearchPlaces>(
    () => SearchPlaces(getIt<DiscoveryRepository>()),
  );
  getIt.registerLazySingleton<ReverseGeocode>(
    () => ReverseGeocode(getIt<DiscoveryRepository>()),
  );

  getIt.registerLazySingleton<CheckLocationPermission>(
    () => CheckLocationPermission(getIt<domain.LocationService>()),
  );
  getIt.registerLazySingleton<RequestForegroundLocation>(
    () => RequestForegroundLocation(getIt<domain.LocationService>()),
  );
  getIt.registerLazySingleton<RequestBackgroundLocation>(
    () => RequestBackgroundLocation(getIt<domain.LocationService>()),
  );
  getIt.registerLazySingleton<OpenAppSettings>(
    () => OpenAppSettings(getIt<domain.LocationService>()),
  );
  getIt.registerLazySingleton<OpenLocationSettings>(
    () => OpenLocationSettings(getIt<domain.LocationService>()),
  );
  getIt.registerLazySingleton<GetCurrentLocation>(
    () => GetCurrentLocation(getIt<domain.LocationService>()),
  );
  getIt.registerLazySingleton<IsLocationServiceEnabled>(
    () => IsLocationServiceEnabled(getIt<domain.LocationService>()),
  );
  getIt.registerLazySingleton<GeofencingSupported>(
    () => GeofencingSupported(getIt<domain.GeofencingService>()),
  );
  getIt.registerLazySingleton<RequestNotificationPermission>(
    () => RequestNotificationPermission(getIt<domain.NotificationService>()),
  );
  getIt.registerLazySingleton<CheckBiometrics>(
    () => CheckBiometrics(getIt<domain.BiometricService>()),
  );
  getIt.registerLazySingleton<UnlockWithBiometrics>(
    () => UnlockWithBiometrics(getIt<domain.BiometricService>()),
  );

  getIt.registerLazySingleton<WatchSyncStatus>(
    () => WatchSyncStatus(getIt<SyncRepository>()),
  );
  getIt.registerLazySingleton<SyncNow>(() => SyncNow(getIt<SyncRepository>()));
  getIt.registerLazySingleton<RequestSync>(
    () => RequestSync(getIt<SyncRepository>()),
  );
}

void _registerBlocs() {
  getIt.registerLazySingleton<SettingsBloc>(
    () => SettingsBloc(
      getIt<WatchSettings>(),
      getIt<GetSettings>(),
      getIt<UpdateSettings>(),
    ),
  );
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      getIt<WatchAuthUser>(),
      getIt<SignInWithEmail>(),
      getIt<SignUpWithEmail>(),
      getIt<SignInWithGoogle>(),
      getIt<ContinueAsDemo>(),
      getIt<SignOut>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerLazySingleton<SyncBloc>(
    () => SyncBloc(getIt<WatchSyncStatus>(), getIt<SyncNow>()),
  );

  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(
      getIt<WatchMissions>(),
      getIt<WatchPlaces>(),
      getIt<WatchTitipanFeed>(),
      getIt<WatchHistory>(),
      getIt<GeofenceManager>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerFactory<PlacesBloc>(
    () => PlacesBloc(
      getIt<WatchPlaces>(),
      getIt<WatchMissions>(),
      getIt<DeletePlace>(),
    ),
  );
  getIt.registerFactory<MissionsBloc>(
    () => MissionsBloc(
      getIt<WatchMissions>(),
      getIt<WatchPlaces>(),
      getIt<GeofenceManager>(),
      getIt<SaveMission>(),
      getIt<DeleteMission>(),
    ),
  );
  getIt.registerFactory<TitipanBloc>(
    () => TitipanBloc(
      getIt<WatchTitipanFeed>(),
      getIt<DeleteTitipan>(),
      getIt<MarkTitipanRead>(),
      getIt<EnsureTitipanInviteLink>(),
      getIt<RefreshTitipan>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerFactory<HistoryBloc>(
    () => HistoryBloc(
      getIt<WatchHistory>(),
      getIt<ClearHistory>(),
      getIt<DrainNativeTransitions>(),
    ),
  );
  getIt.registerFactory<PermissionsBloc>(
    () => PermissionsBloc(
      getIt<domain.LocationService>(),
      getIt<domain.NotificationService>(),
      getIt<GeofenceManager>(),
      getIt<SettingsRepository>(),
      getIt<GetSettings>(),
      getIt<UpdateSettings>(),
    ),
  );
  getIt.registerFactory<PlacePickerBloc>(
    () => PlacePickerBloc(
      getIt<SearchPlaces>(),
      getIt<GetCurrentLocation>(),
      getIt<ReverseGeocode>(),
    ),
  );
  getIt.registerFactory<NaturalBloc>(
    () => NaturalBloc(
      parse: getIt<ParseNaturalReminder>(),
      watchPlaces: getIt<WatchPlaces>(),
      savePlace: getIt<SavePlace>(),
      saveMission: getIt<SaveMission>(),
      auth: getIt<AuthRepository>(),
    ),
  );
  getIt.registerFactoryParam<PlaceFormBloc, String?, PlaceSeed?>(
    (placeId, seed) => PlaceFormBloc(
      getPlace: getIt<GetPlace>(),
      savePlace: getIt<SavePlace>(),
      deletePlace: getIt<DeletePlace>(),
      getCurrentLocation: getIt<GetCurrentLocation>(),
      reverseGeocode: getIt<ReverseGeocode>(),
      getSettings: getIt<GetSettings>(),
      auth: getIt<AuthRepository>(),
      placeId: placeId,
      seed: seed,
    ),
  );
  getIt.registerFactoryParam<MissionFormBloc, MissionFormArgs, void>(
    (args, _) => MissionFormBloc(
      getMission: getIt<GetMission>(),
      getPlaces: getIt<GetPlaces>(),
      saveMission: getIt<SaveMission>(),
      deleteMission: getIt<DeleteMission>(),
      auth: getIt<AuthRepository>(),
      args: args,
    ),
  );
  getIt.registerFactoryParam<TitipanFormBloc, TitipanFormSeed?, void>(
    (seed, _) => TitipanFormBloc(
      getPlaces: getIt<GetPlaces>(),
      saveTitipan: getIt<SaveTitipan>(),
      ensureLink: getIt<EnsureTitipanInviteLink>(),
      auth: getIt<AuthRepository>(),
      gateway: getIt<CloudGateway>(),
      seed: seed,
    ),
  );
  getIt.registerFactoryParam<InviteBloc, String, void>(
    (token, _) => InviteBloc(
      acceptInvite: getIt<AcceptTitipanInvite>(),
      getTitipan: getIt<GetTitipan>(),
      auth: getIt<AuthRepository>(),
      token: token,
    ),
  );
}
