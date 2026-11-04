// Regressions from emulator run 40463875634 (flows 29 and 30).
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/district/district_lookup.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/widgets/app_drawer.dart';
import 'package:temple_app/widgets/directory_filter_bar.dart';

import 'helpers/fake_admin_auth.dart';

Temple _temple({String id = 't1', String state = 'Tamil Nadu'}) => Temple(
  id: id,
  name: 'Meenakshi Amman Temple',
  state: state,
  city: 'Madurai',
  deity: 'Devi',
  imageUrl: '',
  description: '',
  story: '',
  location: 'Madurai, Tamil Nadu',
  timings: '',
  specialities: const [],
  latitude: 9.9195,
  longitude: 78.1193,
);

Future<Uint8List> _syntheticBoundaries() async => Uint8List.fromList(
  File('test/fixtures/synthetic_districts.dsb').readAsBytesSync(),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    TempleService.readsBlocked = () => true;
    TempleService.published = [_temple()];
  });
  tearDown(TempleService.resetSessionForTest);

  testWidgets('header pull dismisses even when the first move has no dy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDirectoryFilterSheet(
                  context: context,
                  temples: [
                    _temple(),
                    _temple(id: 't2', state: 'Kerala'),
                  ],
                  selectedState: null,
                  selectedDeity: null,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);

    // `adb shell input swipe` repeats the down point as its first move.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Filters')),
    );
    await gesture.moveBy(Offset.zero);
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsNothing);
  });

  testWidgets('drawer filter chips wait for the directory', (tester) async {
    final pending = Completer<List<Temple>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: AppDrawer(templesLoader: () => pending.future),
          body: const SizedBox.expand(),
        ),
      ),
    );
    final ScaffoldState scaffold = tester.firstState(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('drawer-filters-loading')), findsOneWidget);
    expect(find.byKey(const Key('filter-chip-state')), findsNothing);

    pending.complete([_temple(), _temple(id: 't2', state: 'Kerala')]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('drawer-filters-loading')), findsNothing);
    expect(find.byKey(const Key('filter-chip-state')), findsOneWidget);
  });

  testWidgets('home warms districts when the directory loads, before a tap', (
    tester,
  ) async {
    final previous = debugWarmDirectoryDistricts;
    addTearDown(() => debugWarmDirectoryDistricts = previous);
    debugWarmDirectoryDistricts = true;
    DistrictDirectory.instance.resetForTest(loadBytes: _syntheticBoundaries);
    addTearDown(DistrictDirectory.instance.resetForTest);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          adminAuth: FakeAdminAuth(),
          adminToolsEnabled: false,
          templesLoader: () async => [_temple()],
        ),
      ),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && !DistrictDirectory.instance.isReady; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pump();
    expect(DistrictDirectory.instance.isReady, isTrue);
    expect(DistrictDirectory.instance.assetLoadCount, 1);
    expect(DistrictDirectory.instance.peek(_temple()), isNotNull);
  });
}
