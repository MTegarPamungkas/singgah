import 'dart:async';

import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/domain/entities/geo_point.dart';
import 'package:singgah/domain/entities/geofence_summary.dart';
import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:singgah/domain/repositories/history_repository.dart';
import 'package:singgah/domain/repositories/mission_repository.dart';
import 'package:singgah/domain/repositories/place_repository.dart';
import 'package:singgah/domain/repositories/settings_repository.dart';
import 'package:singgah/domain/repositories/titipan_repository.dart';
import 'package:singgah/domain/services/geofence_manager.dart';
import 'package:singgah/domain/services/geofencing_service.dart';
import 'package:singgah/domain/services/location_service.dart';
import 'package:singgah/domain/usecases/geofence_planner.dart';
import 'package:singgah/domain/usecases/titipan_visibility.dart';

/// Owns the lifecycle of OS geofences: decides the active set, registers it,
/// and drains transitions captured while the app was closed.
class GeofenceCoordinator implements GeofenceManager {
  GeofenceCoordinator({
    required LocalStore store,
    required AuthRepository auth,
    required PlaceRepository places,
    required MissionRepository missions,
    required TitipanRepository titipan,
    required SettingsRepository settings,
    required LocationService location,
    required GeofencingService geofencing,
    required HistoryRepository history,
    GeofencePlanner planner = const GeofencePlanner(),
  }) : _store = store,
       _auth = auth,
       _places = places,
       _missions = missions,
       _titipan = titipan,
       _settings = settings,
       _location = location,
       _geofencing = geofencing,
       _history = history,
       _planner = planner;

  final LocalStore _store;
  final AuthRepository _auth;
  final PlaceRepository _places;
  final MissionRepository _missions;
  final TitipanRepository _titipan;
  final SettingsRepository _settings;
  final LocationService _location;
  final GeofencingService _geofencing;
  final HistoryRepository _history;
  final GeofencePlanner _planner;

  final StreamController<GeofenceSummary> _summaryController =
      StreamController<GeofenceSummary>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _debounce;
  bool _running = false;
  bool _started = false;
  GeoPoint? _lastCenter;
  List<String> _lastRequestIds = const [];
  DateTime? _lastPlanAt;

  @override
  Stream<GeofenceSummary> get summaries async* {
    yield await summary();
    yield* _summaryController.stream;
  }

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _subscriptions.add(
      _missions.watchMissions().listen((_) => requestRefresh()),
    );
    _subscriptions.add(_places.watchPlaces().listen((_) => requestRefresh()));
    _subscriptions.add(_titipan.watchFeed().listen((_) => requestRefresh()));
    _subscriptions.add(
      _settings.watchSettings().listen((_) => requestRefresh()),
    );
    await syncTransitions();
    await refresh(force: true);
  }

  void requestRefresh() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 700),
      () => refresh(force: true),
    );
  }

  @override
  Future<GeofenceSummary> summary() async {
    final permission = await _location.checkPermission();
    return GeofenceSummary(
      supported: _geofencing.isSupported,
      enabled: (await _settings.getSettings()).locationRemindersEnabled,
      permission: permission,
      registered: _lastRequestIds.length,
      skipped: (_store.getMeta('geofence_skipped_count') as int?) ?? 0,
      updatedAt: _lastPlanAt,
      refreshing: _running,
    );
  }

  @override
  Future<void> refresh({bool force = false}) async {
    if (_running) return;
    _running = true;
    _emitFresh();
    try {
      final settings = await _settings.getSettings();
      final permission = await _location.checkPermission();
      if (!settings.locationRemindersEnabled ||
          !_geofencing.isSupported ||
          (permission != LocationPermissionState.grantedForeground &&
              permission != LocationPermissionState.grantedBackground)) {
        await _geofencing.clearAll();
        _lastRequestIds = const [];
        await _store.setMeta('geofence_skipped_count', 0);
        _lastPlanAt = DateTime.now();
        return;
      }

      final location = await _location.currentLocation();
      final center = location?.point;
      if (!force &&
          !_planner.shouldRefresh(previous: _lastCenter, current: center)) {
        return;
      }
      _lastCenter = center ?? _lastCenter;

      final places = <String, Titik>{
        for (final place in await _places.getPlaces()) place.id: place,
      };
      final missions = await _missions.getMissions();
      final feed = await _titipan.getFeed();
      final accepted = TitipanVisibility.acceptedIds(
        recipients: feed.recipients,
        userId: _currentUserId(),
      );
      final plan = _planner.plan(
        missions: missions,
        places: places,
        titipans: feed.titipans,
        acceptedTitipanIds: accepted,
        now: DateTime.now(),
        current: center,
        maxCount: AppConfig.maxGeofences,
      );
      final result = await _geofencing.syncGeofences(plan.requests);
      _lastRequestIds = result.registered;
      _lastPlanAt = plan.generatedAt;
      await _store.setMeta('geofence_skipped_count', plan.skipped.length);
      await _store.setMeta(
        'geofence_registered_count',
        result.registered.length,
      );
      await _store.setMeta(
        'geofence_plan_at',
        plan.generatedAt.toIso8601String(),
      );
    } catch (_) {
      // Geofence refresh is best effort; the next data change or resume will
      // try again.
    } finally {
      _running = false;
      _emitFresh();
    }
  }

  @override
  Future<int> syncTransitions() async {
    try {
      return await _history.drainNativeTransitions();
    } catch (_) {
      return 0;
    }
  }

  String _currentUserId() {
    // The repositories scope writes by owner; accepted Titipan ids are read
    // from the local recipient cache, which is already user-scoped.
    return _auth.currentUser?.id ??
        _store.getMeta(LocalStore.ownerMetaKey)?.toString() ??
        '';
  }

  void _emitFresh() {
    summary().then((value) {
      if (!_summaryController.isClosed) _summaryController.add(value);
    });
  }

  Future<void> dispose() async {
    _debounce?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _summaryController.close();
  }
}
