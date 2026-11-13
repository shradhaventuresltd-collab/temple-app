import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/widgets/app_drawer.dart';
import 'package:temple_app/widgets/filter_sheet.dart';

import 'helpers/fake_admin_auth.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final temple = Temple(
    name: 'Meenakshi Amman Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Devi',
    imageUrl: '',
    description: 'A historic temple.',
    story: 'Story',
    location: 'Madurai, Tamil Nadu',
    timings: '6am–9pm',
    specialities: const ['Tower'],
    latitude: 9.9195,
    longitude: 78.1193,
  );

  for (final code in ['ml', 'ta']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('home $code x$scale at 360dp does not overflow', (
        tester,
      ) async {
        await _expectNoOverflow(
          tester,
          locale: Locale(code),
          scale: scale,
          home: HomeScreen(
            adminAuth: FakeAdminAuth(),
            templesLoader: () async => [temple],
          ),
        );
      });

      testWidgets('drawer $code x$scale at 360dp does not overflow', (
        tester,
      ) async {
        await _expectNoOverflow(
          tester,
          locale: Locale(code),
          scale: scale,
          home: Scaffold(
            drawer: AppDrawer(templesLoader: () async => [temple]),
            body: const SizedBox.shrink(),
          ),
          afterPump: (tester) async {
            tester
                .firstState<ScaffoldState>(find.byType(Scaffold))
                .openDrawer();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
          },
        );
      });

      testWidgets('detail $code x$scale at 360dp does not overflow', (
        tester,
      ) async {
        await _expectNoOverflow(
          tester,
          locale: Locale(code),
          scale: scale,
          home: TempleDetailScreen(temple: temple),
        );
      });

      testWidgets('filter sheet $code x$scale at 360dp does not overflow', (
        tester,
      ) async {
        await _expectNoOverflow(
          tester,
          locale: Locale(code),
          scale: scale,
          home: Builder(
            builder: (context) {
              return FilterSheetScaffold(
                title: context.l10n.filterSheetStateTitle,
                sectionKey: const Key('filter-section-state'),
                searchHint: context.l10n.filterSheetSearchStateHint,
                resultLabel: context.l10n.directoryFilterResultLabel(12),
                any: FilterSheetOption(
                  id: 'any',
                  label: context.l10n.filterSheetAnyStateLabel,
                  count: 12,
                  value: '',
                ),
                sections: [
                  FilterSheetSection(
                    id: 'south',
                    title: context.l10n.filterSheetRegionSouthHeading,
                    options: [
                      FilterSheetOption(
                        id: 'tn',
                        label: context.l10n.filterStateTamilNadu,
                        count: 4,
                        value: 'Tamil Nadu',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      });
    }
  }
}

Future<void> _expectNoOverflow(
  WidgetTester tester, {
  required Locale locale,
  required double scale,
  required Widget home,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  final overflows = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (text.contains('overflowed')) overflows.add(text);
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocale.localizationsDelegates,
      supportedLocales: AppLocale.supportedLocales,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  if (afterPump != null) await afterPump(tester);
  expect(overflows, isEmpty);
}
