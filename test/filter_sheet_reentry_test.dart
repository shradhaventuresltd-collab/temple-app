import 'dart:async';

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

const _chips = ['state', 'district', 'deity'];

enum _Close { select, x, swipe, back, outside, clear }

enum _Entry { homeBrowse, drawerAllTemples, drawerState, drawerDistrict }

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final temples = [
    _temple(
      name: 'Meenakshi Amman Temple',
      state: 'Tamil Nadu',
      city: 'Madurai',
      deity: 'Devi',
      latitude: 9.9195,
      longitude: 78.1193,
    ),
    _temple(
      name: 'Shore Temple',
      state: 'Tamil Nadu',
      city: 'Mahabalipuram',
      deity: 'Shiva',
      latitude: 12.6167,
      longitude: 80.1918,
    ),
    _temple(
      name: 'Vaikom Mahadeva Temple',
      state: 'Kerala',
      city: 'Kottayam',
      deity: 'Shiva',
      latitude: 9.75,
      longitude: 76.4,
    ),
  ];

  String? districtOf(Temple temple) => temple.city;

  setUp(() {
    TempleService.readsBlocked = () => true;
    TempleService.published = temples;
    DistrictDirectory.instance.resetForTest();
  });

  tearDown(() {
    TempleService.resetSessionForTest();
    DistrictDirectory.instance.resetForTest();
  });

  testWidgets(
    'selecting a district then closing leaves the other chips able to open',
    (tester) async {
      await _size(tester);
      await _pumpBar(tester, temples: temples, districtOf: districtOf);
      for (final how in _Close.values) {
        await _openChip(tester, 'district');
        await _tapRealOption(tester, 'district');
        await _close(tester, how);
        expect(find.byKey(const Key('filter-sheet')), findsNothing);
        await _openChip(tester, 'state');
        await _close(tester, _Close.back);
        await _openChip(tester, 'deity');
        await _close(tester, _Close.back);
        await _clearBar(tester);
      }
    },
  );

  for (final kind in ['double-tap', 'other-chip']) {
    testWidgets('tap during prepare ($kind) stacks no sheets', (tester) async {
      await _size(tester);
      final gate = Completer<void>();
      await _pumpBar(
        tester,
        temples: temples,
        prepareDistricts: () async {
          await gate.future;
          return districtOf;
        },
      );

      await tester.tap(find.byKey(const Key('filter-chip-district')));
      if (kind == 'other-chip') {
        await tester.tap(
          find.byKey(const Key('filter-chip-state')),
          warnIfMissed: false,
        );
        await tester.tap(
          find.byKey(const Key('filter-chip-deity')),
          warnIfMissed: false,
        );
      } else {
        await tester.tap(
          find.byKey(const Key('filter-chip-district')),
          warnIfMissed: false,
        );
      }
      await tester.pump();
      expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
      expect(find.byKey(const Key('filter-district-loading')), findsOneWidget);
      gate.complete();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filter-district-loading')), findsNothing);
      expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
      expect(find.byKey(const Key('filter-section-district')), findsOneWidget);
      await _tapRealOption(tester, 'district');
      await _close(tester, _Close.x);
      expect(find.byKey(const Key('filter-sheet')), findsNothing);
      await _openChip(tester, 'state');
      expect(find.byKey(const Key('filter-section-state')), findsOneWidget);
    });
  }

  testWidgets('a failed prepare resets the guard', (tester) async {
    await _size(tester);
    var calls = 0;
    await _pumpBar(
      tester,
      temples: temples,
      prepareDistricts: () async {
        calls += 1;
        if (calls == 1) throw StateError('boundaries');
        return districtOf;
      },
    );

    await tester.tap(find.byKey(const Key('filter-chip-district')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
    expect(find.byKey(const Key('filter-district-error')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);

    await tester.tap(find.byKey(const Key('filter-chip-district')));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
    expect(find.byKey(const Key('filter-section-district')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'double-tap All districts on All Temples keeps the list and the next chip',
    (tester) async {
      await _size(tester);
      final gate = Completer<String? Function(Temple)?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => Scaffold(
                          body: Column(
                            children: [
                              const Text('All Temples'),
                              DirectoryFilterBar(
                                temples: temples,
                                selectedState: null,
                                selectedDeity: null,
                                prepareDistricts: () => gate.future,
                                onChanged: (_, _, _) {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open All Temples'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open All Temples'));
      await tester.pumpAndSettle();
      expect(find.text('All Temples'), findsOneWidget);
      expect(_canPop(tester), isTrue);

      await tester.tap(find.byKey(const Key('filter-chip-district')));
      await tester.tap(
        find.byKey(const Key('filter-chip-district')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
      expect(find.byKey(const Key('filter-district-loading')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('filter-sheet')), findsNothing);
      expect(find.text('All Temples'), findsOneWidget);
      expect(_canPop(tester), isTrue);

      await tester.tap(find.byKey(const Key('filter-chip-deity')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-section-deity')), findsOneWidget);

      gate.complete(districtOf);
      await tester.pump();
      await tester.pumpAndSettle();
    },
  );

  for (final entry in _Entry.values) {
    testWidgets('${entry.name} chip pairs reopen after every close', (
      tester,
    ) async {
      await _size(tester);
      await _openEntry(tester, entry, temples);
      for (final a in _chips) {
        for (final b in _chips) {
          for (final how in _Close.values) {
            final where = '${entry.name} $a -${how.name}-> $b';
            await _openChip(tester, a, where: where);
            await _tapRealOption(tester, a);
            await _close(tester, how);
            expect(
              find.byKey(const Key('filter-sheet')),
              findsNothing,
              reason: where,
            );
            await _openChip(tester, b, where: where);
            expect(
              find.byKey(Key('filter-section-$b')),
              findsOneWidget,
              reason: where,
            );
            await _close(tester, _Close.back);
            await _clearBar(tester);
          }
        }
      }
    });
  }
}

Temple _temple({
  required String name,
  required String state,
  required String city,
  required String deity,
  required double latitude,
  required double longitude,
}) {
  return Temple(
    name: name,
    state: state,
    city: city,
    deity: deity,
    imageUrl: '',
    description: '',
    story: '',
    location: '$city, $state',
    timings: '',
    specialities: const [],
    latitude: latitude,
    longitude: longitude,
  );
}

bool _canPop(WidgetTester tester) {
  return tester.state<NavigatorState>(find.byType(Navigator)).canPop();
}

Future<void> _size(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpBar(
  WidgetTester tester, {
  required List<Temple> temples,
  String? Function(Temple temple)? districtOf,
  Future<String? Function(Temple)?> Function()? prepareDistricts,
}) async {
  String? state;
  String? deity;
  String? district;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return DirectoryFilterBar(
              temples: temples,
              selectedState: state,
              selectedDeity: deity,
              selectedDistrict: district,
              districtOf: prepareDistricts == null ? districtOf : null,
              prepareDistricts: prepareDistricts,
              onChanged: (nextState, nextDeity, nextDistrict) {
                setState(() {
                  state = nextState;
                  deity = nextDeity;
                  district = nextDistrict;
                });
              },
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openEntry(
  WidgetTester tester,
  _Entry entry,
  List<Temple> temples,
) async {
  await tester.runAsync(() => DistrictDirectory.instance.ensureFor(temples));
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        adminAuth: FakeAdminAuth(),
        adminToolsEnabled: false,
        templesLoader: () async => temples,
      ),
    ),
  );
  await tester.pumpAndSettle();

  switch (entry) {
    case _Entry.homeBrowse:
      await tester.tap(find.byKey(const Key('home-browse-temples')));
      await tester.pumpAndSettle();
      expect(find.byType(TempleListScreen), findsOneWidget);
    case _Entry.drawerAllTemples:
      await _openDrawer(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('All Temples'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TempleListScreen), findsOneWidget);
    case _Entry.drawerState:
      await _openDrawer(tester);
      await _openChip(tester, 'state');
      await tester.tap(find.byKey(const Key('filter-option-state-Kerala')));
      await tester.pump();
      await _close(tester, _Close.select);
      await _tapDrawerBrowse(tester);
    case _Entry.drawerDistrict:
      await _openDrawer(tester);
      await _openChip(tester, 'district');
      await _tapRealOption(tester, 'district');
      await _close(tester, _Close.select);
      await _tapDrawerBrowse(tester);
  }
  expect(find.byKey(const Key('filter-chip-state')), findsOneWidget);
  expect(find.byKey(const Key('filter-chip-district')), findsOneWidget);
  expect(find.byKey(const Key('filter-chip-deity')), findsOneWidget);
}

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  expect(find.byType(Drawer), findsOneWidget);
}

Future<void> _tapDrawerBrowse(WidgetTester tester) async {
  final browse = find.descendant(
    of: find.byType(Drawer),
    matching: find.textContaining('Browse'),
  );
  await tester.ensureVisible(browse);
  await tester.tap(browse);
  await tester.pumpAndSettle();
  expect(find.byType(TempleListScreen), findsOneWidget);
}

Future<void> _openChip(
  WidgetTester tester,
  String chip, {
  String? where,
}) async {
  final key = find.byKey(Key('filter-chip-$chip'));
  await tester.ensureVisible(key.hitTestable());
  await tester.tap(key.hitTestable());
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('filter-sheet')), findsOneWidget, reason: where);
  expect(
    find.byKey(Key('filter-section-$chip')),
    findsOneWidget,
    reason: where,
  );
}

Future<void> _tapRealOption(WidgetTester tester, String section) async {
  final option = find.byWidgetPredicate((widget) {
    final key = widget.key;
    if (key is! ValueKey<String>) return false;
    final value = key.value;
    return value.startsWith('filter-option-$section-') &&
        !value.endsWith('-any');
  });
  expect(option, findsWidgets);
  await tester.ensureVisible(option.first);
  await tester.tap(option.first);
  await tester.pump();
}

Future<void> _close(WidgetTester tester, _Close how) async {
  switch (how) {
    case _Close.select:
      await tester.ensureVisible(find.byKey(const Key('filter-sheet-apply')));
      await tester.tap(find.byKey(const Key('filter-sheet-apply')));
    case _Close.x:
      await tester.tap(find.byKey(const Key('filter-sheet-close')));
    case _Close.swipe:
      await tester.drag(find.text('Filters'), const Offset(0, 400));
    case _Close.back:
      await tester.binding.handlePopRoute();
    case _Close.outside:
      await tester.tapAt(const Offset(12, 12));
    case _Close.clear:
      await tester.tap(find.byKey(const Key('filter-sheet-clear')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('filter-sheet-apply')));
      await tester.tap(find.byKey(const Key('filter-sheet-apply')));
  }
  await tester.pumpAndSettle();
}

Future<void> _clearBar(WidgetTester tester) async {
  final clear = find.byKey(const Key('filter-clear'));
  if (clear.evaluate().isEmpty) return;
  await tester.tap(clear.hitTestable());
  await tester.pumpAndSettle();
}
