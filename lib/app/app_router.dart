import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:singgah/app/app_shell.dart';
import 'package:singgah/app/invite_intent.dart';
import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/core/di/injection_container.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/core/widgets/singgah_mark.dart';
import 'package:singgah/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:singgah/features/auth/presentation/pages/auth_page.dart';
import 'package:singgah/features/history/presentation/bloc/history_bloc.dart';
import 'package:singgah/features/history/presentation/pages/history_page.dart';
import 'package:singgah/features/home/presentation/bloc/home_bloc.dart';
import 'package:singgah/features/home/presentation/pages/home_page.dart';
import 'package:singgah/features/missions/presentation/bloc/mission_form_bloc.dart';
import 'package:singgah/features/missions/presentation/bloc/missions_bloc.dart';
import 'package:singgah/features/missions/presentation/pages/mission_form_page.dart';
import 'package:singgah/features/missions/presentation/pages/missions_page.dart';
import 'package:singgah/features/natural/presentation/bloc/natural_bloc.dart';
import 'package:singgah/features/natural/presentation/pages/natural_page.dart';
import 'package:singgah/features/permissions/presentation/bloc/permissions_bloc.dart';
import 'package:singgah/features/permissions/presentation/pages/permissions_page.dart';
import 'package:singgah/features/places/presentation/bloc/place_form_bloc.dart';
import 'package:singgah/features/places/presentation/bloc/places_bloc.dart';
import 'package:singgah/features/places/presentation/pages/place_form_page.dart';
import 'package:singgah/features/places/presentation/pages/place_picker_page.dart';
import 'package:singgah/features/places/presentation/pages/places_page.dart';
import 'package:singgah/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:singgah/features/settings/presentation/pages/profile_page.dart';
import 'package:singgah/features/settings/presentation/pages/settings_page.dart';
import 'package:singgah/features/titipan/presentation/bloc/invite_bloc.dart';
import 'package:singgah/features/titipan/presentation/bloc/titipan_bloc.dart';
import 'package:singgah/features/titipan/presentation/bloc/titipan_form_bloc.dart';
import 'package:singgah/features/titipan/presentation/pages/chat_page.dart';
import 'package:singgah/features/titipan/presentation/pages/friends_page.dart';
import 'package:singgah/features/titipan/presentation/pages/invite_page.dart';
import 'package:singgah/features/titipan/presentation/pages/titipan_detail_page.dart';
import 'package:singgah/features/titipan/presentation/pages/titipan_form_page.dart';
import 'package:singgah/features/titipan/presentation/pages/titipan_page.dart';

GoRouter createRouter(AuthBloc auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(auth.stream),
    redirect: (context, state) {
      final session = auth.state;
      final location = state.matchedLocation;
      if (session.resolving) {
        if (location.startsWith('/invite/')) {
          InviteIntent.remember(state.pathParameters['token'] ?? '');
        }
        return location == '/splash' ? null : '/splash';
      }
      if (!session.signedIn) {
        if (location.startsWith('/invite/')) {
          InviteIntent.remember(state.pathParameters['token'] ?? '');
        }
        return location == '/auth' ? null : '/auth';
      }

      final onboarding = getIt<SettingsBloc>().state.onboardingCompleted;
      final pending = InviteIntent.token;
      final atEntry =
          location == '/auth' || location == '/splash' || location == '/';
      if (atEntry) {
        if (pending != null) {
          final token = InviteIntent.take();
          return '/invite/$token';
        }
        return onboarding ? '/home' : '/permissions';
      }
      if (!onboarding &&
          location != '/permissions' &&
          !location.startsWith('/invite/') &&
          !location.startsWith('/titipan/')) {
        return '/permissions';
      }
      if (location == '/') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<HomeBloc>(),
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/places',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<PlacesBloc>(),
                  child: const PlacesPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/missions',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<MissionsBloc>(),
                  child: const MissionsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/titipan',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<TitipanBloc>(),
                  child: const TitipanPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<HistoryBloc>(),
                  child: const HistoryPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/places/picker',
        builder: (context, state) => const PlacePickerPage(),
      ),
      GoRoute(
        path: '/places/new',
        builder: (context, state) {
          final seed = state.extra is PlaceSeed
              ? state.extra as PlaceSeed
              : null;
          return BlocProvider(
            create: (_) => getIt<PlaceFormBloc>(param1: null, param2: seed),
            child: const PlaceFormPage(),
          );
        },
      ),
      GoRoute(
        path: '/places/:id/edit',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<PlaceFormBloc>(
            param1: state.pathParameters['id']!,
            param2: null,
          ),
          child: const PlaceFormPage(),
        ),
      ),
      GoRoute(
        path: '/missions/new',
        builder: (context, state) {
          final seed = state.extra is MissionSeed
              ? state.extra as MissionSeed
              : null;
          return BlocProvider(
            create: (_) =>
                getIt<MissionFormBloc>(param1: MissionFormArgs(seed: seed)),
            child: const MissionFormPage(),
          );
        },
      ),
      GoRoute(
        path: '/missions/:id/edit',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<MissionFormBloc>(
            param1: MissionFormArgs(missionId: state.pathParameters['id']!),
          ),
          child: const MissionFormPage(),
        ),
      ),
      GoRoute(
        path: '/titipan/new',
        builder: (context, state) {
          final seed = state.extra is TitipanFormSeed
              ? state.extra as TitipanFormSeed
              : null;
          return BlocProvider(
            create: (_) => getIt<TitipanFormBloc>(param1: seed),
            child: const TitipanFormPage(),
          );
        },
      ),
      GoRoute(
        path: '/titipan/:id',
        builder: (context, state) =>
            TitipanDetailPage(titipanId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/natural',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<NaturalBloc>(),
          child: const NaturalPage(),
        ),
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<PermissionsBloc>(),
          child: const PermissionsPage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/invite/:token',
        builder: (context, state) => BlocProvider(
          create: (_) =>
              getIt<InviteBloc>(param1: state.pathParameters['token']!),
          child: const InvitePage(),
        ),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsPage(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final extra = state.extra is Map ? state.extra as Map : const {};
          final participants = extra['participants'];
          return ChatPage(
            conversationId: state.pathParameters['conversationId']!,
            title: extra['title']?.toString() ?? 'Chat',
            participantIds: participants is List
                ? participants.map((id) => id.toString()).toList()
                : const [],
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: PageScroll(
        children: [
          EmptyState(
            icon: Icons.search_off_rounded,
            title: context.l10n.notFound,
            body: state.uri.toString(),
            action: FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined, size: 18),
              label: Text(context.l10n.home),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SinggahMark(size: 78),
              const SizedBox(height: 26),
              Text(
                AppConfig.appName.toUpperCase(),
                style: context.texts.labelLarge?.copyWith(
                  letterSpacing: 4.6,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.singgah.ink,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  l10n.tagline,
                  textAlign: TextAlign.center,
                  style: context.texts.displaySmall?.copyWith(
                    fontSize: 25,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.singgah.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
