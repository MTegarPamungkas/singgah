import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:flutter/material.dart';

import 'package:singgah/app/app.dart';
import 'package:singgah/app/app_maintenance.dart';
import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/core/di/injection_container.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/sync/sync_engine.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = LocalStore();
  await store.init();

  appwrite.Client? appwriteClient;
  if (AppConfig.hasAppwrite) {
    try {
      appwriteClient = appwrite.Client()
          .setEndpoint(AppConfig.appwriteEndpoint)
          .setProject(AppConfig.appwriteProjectId);
    } catch (error, stackTrace) {
      debugPrint('Appwrite initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      appwriteClient = null;
    }
  }

  await configureDependencies(store: store, appwriteClient: appwriteClient);
  await getIt<SyncEngine>().start();
  await getIt<AppMaintenance>().start();
  runApp(const SinggahApp());
}
