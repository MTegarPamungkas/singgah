import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';

Widget harness(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    locale: const Locale('id'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('empty state renders bilingual copy', (tester) async {
    await tester.pumpWidget(
      harness(
        const EmptyState(
          icon: Icons.place_outlined,
          title: 'Belum ada Titik.',
          body: 'Tambahkan rumah atau kantor.',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Belum ada Titik.'), findsOneWidget);
    expect(find.text('Tambahkan rumah atau kantor.'), findsOneWidget);
  });

  testWidgets('loading state shows the label', (tester) async {
    await tester.pumpWidget(harness(const LoadingState()));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Menyiapkan…'), findsOneWidget);
  });
}
