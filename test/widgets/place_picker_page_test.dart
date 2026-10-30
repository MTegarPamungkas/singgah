import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:singgah/core/di/injection_container.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';
import 'package:singgah/domain/usecases/device_usecases.dart';
import 'package:singgah/domain/usecases/discovery_usecases.dart';
import 'package:singgah/features/places/presentation/bloc/place_picker_bloc.dart';
import 'package:singgah/features/places/presentation/pages/place_picker_page.dart';

class MockSearchPlaces extends Mock implements SearchPlaces {}

class MockCurrentLocation extends Mock implements GetCurrentLocation {}

class MockReverseGeocode extends Mock implements ReverseGeocode {}

class _PickerHost extends StatefulWidget {
  const _PickerHost();

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends State<_PickerHost> {
  String _selected = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selected.isEmpty ? 'NOTHING' : _selected),
            TextButton(
              onPressed: () async {
                final result = await context.push<PlacePickResult>(
                  '/places/picker',
                );
                if (!mounted || result == null) return;
                setState(() => _selected = result.name);
              },
              child: const Text('OPEN'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  setUp(() async {
    final search = MockSearchPlaces();
    final current = MockCurrentLocation();
    final reverse = MockReverseGeocode();
    when(() => current()).thenAnswer((_) async => null);
    when(() => search(any(), localeCode: any(named: 'localeCode'))).thenAnswer(
      (_) async => const [
        PlaceSuggestion(
          name: 'Alfamart dekat rumah',
          address: 'Jl. Kemang Raya No. 12',
          latitude: -6.2607,
          longitude: 106.8132,
        ),
      ],
    );
    when(() => reverse(any(), any(), localeCode: any(named: 'localeCode')))
        .thenAnswer((_) async => 'Jl. Kemang Raya No. 12');

    getIt.registerFactory<PlacePickerBloc>(
      () => PlacePickerBloc(search, current, reverse),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('searches, selects a place, and returns it to the caller', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/host',
      routes: [
        GoRoute(
          path: '/host',
          builder: (context, state) => const _PickerHost(),
        ),
        GoRoute(
          path: '/places/picker',
          builder: (context, state) => const PlacePickerPage(),
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
    await tester.pump();
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'alfa');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Alfamart dekat rumah'), findsOneWidget);
    await tester.tap(find.text('Alfamart dekat rumah'));
    await tester.pumpAndSettle();

    expect(find.text('Alfamart dekat rumah'), findsOneWidget);
    expect(find.text('NOTHING'), findsNothing);
  });
}
