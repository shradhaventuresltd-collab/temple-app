import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/screens/temples_near_me_screen.dart';

import 'filter_sheet_support.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('near_me_pickers_filter_sheet_test', (tester) async {
    useFilterSurface(tester);
    final temples = [
      filterTemple(
        name: 'Meenakshi Amman Temple',
        state: 'Tamil Nadu',
        city: 'Madurai',
        deity: 'Devi',
        latitude: 9.9195,
        longitude: 78.1193,
      ),
      filterTemple(
        name: 'Vaikom Mahadeva Temple',
        state: 'Kerala',
        city: 'Kottayam',
        deity: 'Shiva',
        latitude: 9.75,
        longitude: 76.4,
      ),
      filterTemple(
        name: 'Somnath Temple',
        state: 'Gujarat',
        city: 'Veraval',
        deity: 'Shiva',
        latitude: 20.888,
        longitude: 70.401,
      ),
    ];
    String? districtOf(Temple temple) => temple.city;

    await tester.pumpWidget(
      MaterialApp(
        home: TemplesNearMeScreen(
          temples: temples,
          location: _DeniedLocation(),
          districtOf: districtOf,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('near-me-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('near-me-state')));
    await tester.pumpAndSettle();
    expect(find.text('Sort from state'), findsOneWidget);
    expect(find.text('NORTH'), findsNothing);
    expect(find.text('SOUTH'), findsOneWidget);
    expect(find.byKey(const Key('filter-sheet-apply')), findsNothing);
    expect(
      find.byKey(const Key('near-me-state-option-Tamil Nadu')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('near-me-state-option-Kerala')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
    expect(find.textContaining('Kerala'), findsWidgets);

    await tester.tap(find.byKey(const Key('near-me-city')));
    await tester.pumpAndSettle();
    expect(find.text('City'), findsWidgets);
    expect(find.text('In Kerala'), findsOneWidget);
    expect(find.byKey(const Key('near-me-city-option-Kottayam')), findsOneWidget);
    await tester.tap(find.byKey(const Key('near-me-city-option-Kottayam')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('near-me-city')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.radio_button_checked), findsWidgets);
    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('near-me-district')));
    await tester.pumpAndSettle();
    expect(find.text('District'), findsWidgets);
    expect(find.text('In Kerala'), findsOneWidget);
    expect(
      find.byKey(const Key('near-me-district-option-Kottayam')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('near-me-district-option-Madurai')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('near-me-district-option-Kottayam')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
  });
}

class _DeniedLocation implements CoarseLocationClient {
  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<CoarsePermission> checkPermission() async => CoarsePermission.denied;

  @override
  Future<CoarsePermission> requestPermission() async => CoarsePermission.denied;

  @override
  Future<CoarseFix> currentFix({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    throw StateError('denied');
  }

  @override
  Future<CoarseFix?> lastKnownFix() async => null;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}
