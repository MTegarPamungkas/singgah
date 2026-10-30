import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/app/app_lock_gate.dart';
import 'package:singgah/app/app_router.dart';
import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/core/di/injection_container.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/domain/entities/app_settings.dart';
import 'package:singgah/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:singgah/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:singgah/features/sync/presentation/bloc/sync_bloc.dart';

class SinggahApp extends StatefulWidget {
  const SinggahApp({super.key});

  @override
  State<SinggahApp> createState() => _SinggahAppState();
}

class _SinggahAppState extends State<SinggahApp> {
  late final GoRouter _router = createRouter(getIt<AuthBloc>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: getIt<SettingsBloc>()),
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<SyncBloc>.value(value: getIt<SyncBloc>()),
      ],
      child: BlocBuilder<SettingsBloc, AppSettings>(
        builder: (context, settings) {
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: switch (settings.themeMode) {
              AppThemeMode.system => ThemeMode.system,
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
            },
            locale: Locale(settings.localeCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            scrollBehavior: const _SinggahScrollBehavior(),
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.3,
                  ),
                ),
                child: AppLockGate(child: child ?? const SizedBox.shrink()),
              );
            },
          );
        },
      ),
    );
  }
}

class _SinggahScrollBehavior extends MaterialScrollBehavior {
  const _SinggahScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
