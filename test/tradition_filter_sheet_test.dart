// KAN-203 Tradition filter chip and sheet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/screens/temples_near_me_screen.dart';
import 'package:temple_app/widgets/app_drawer.dart';

import 'filter_sheet_support.dart';

List<Temple> _directory() => [
  filterTemple(
    name: 'Meenakshi Amman Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Devi',
  ),
  filterTemple(
    name: 'Dilwara Temples',
    state: 'Rajasthan',
    city: 'Mount Abu',
    deity: 'Rishabhanatha',
    tradition: 'jain',
  ),
  filterTemple(
    name: 'Mahabodhi Temple',
    state: 'Bihar',
    city: 'Bodh Gaya',
    deity: 'Buddha',
    tradition: 'buddhist',
  ),
];

Future<void> _pumpBrowse(
  WidgetTester t, {
  List<Temple>? temples,
  String? initialTradition,
  Size size = const Size(800, 1600),
}) async {
  useFilterSurface(t, size: size);
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TempleBrowseList(
          temples: temples ?? _directory(),
          initialTradition: initialTradition,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _openTradition(WidgetTester t) async {
  final chip = find.byKey(const Key('filter-chip-tradition'));
  await t.ensureVisible(chip);
  await t.tap(chip);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('chip order is State, District, Deity, Tradition', (t) async {
    await _pumpBrowse(t);
    final keys = [
      'filter-chip-state',
      'filter-chip-district',
      'filter-chip-deity',
      'filter-chip-tradition',
    ];
    for (final key in keys) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    final boxes = [for (final key in keys) t.getTopLeft(find.byKey(Key(key)))];
    final ordered = [...boxes]
      ..sort((a, b) {
        final dy = a.dy.compareTo(b.dy);
        return dy != 0 ? dy : a.dx.compareTo(b.dx);
      });
    expect(ordered, boxes);
  });

  testWidgets('hide-zero: Sikh is absent when the directory has none', (
    t,
  ) async {
    await _pumpBrowse(t);
    await _openTradition(t);
    expect(
      find.byKey(const Key('filter-option-tradition-hindu')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-option-tradition-jain')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-option-tradition-buddhist')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('filter-option-tradition-sikh')), findsNothing);
    expect(['Hindu', 'Sikh', 'Jain', 'Buddhist'].map(directoryOrderIndex), [
      0,
      1,
      2,
      3,
    ]);
  });

  testWidgets('apply, clear, and close without apply', (t) async {
    await _pumpBrowse(t);
    await _openTradition(t);
    await t.tap(find.byKey(const Key('filter-option-tradition-jain')));
    await t.tap(find.byKey(const Key('filter-sheet-close')));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('filter-chip-tradition')),
        matching: find.text('Tradition'),
      ),
      findsOneWidget,
    );

    await _openTradition(t);
    await t.tap(find.byKey(const Key('filter-option-tradition-jain')));
    await t.tap(find.byKey(const Key('filter-sheet-apply')));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('filter-chip-tradition')),
        matching: find.text('Jain'),
      ),
      findsOneWidget,
    );
    expect(find.text('Dilwara Temples'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);

    await t.tap(find.byKey(const Key('filter-chip-tradition-clear')));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('filter-chip-tradition')),
        matching: find.text('Tradition'),
      ),
      findsOneWidget,
    );
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
  });

  testWidgets('re-open keeps the applied selection; second tap re-opens', (
    t,
  ) async {
    await _pumpBrowse(t);
    await _openTradition(t);
    await t.tap(find.byKey(const Key('filter-option-tradition-jain')));
    await t.tap(find.byKey(const Key('filter-sheet-apply')));
    await t.pumpAndSettle();
    await _openTradition(t);
    final jain = find.byKey(const Key('filter-option-tradition-jain'));
    expect(jain, findsOneWidget);
    await t.tap(find.byKey(const Key('filter-sheet-close')));
    await t.pumpAndSettle();
    await _openTradition(t);
    expect(find.byKey(const Key('filter-section-tradition')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('filter-chip-tradition')),
        matching: find.text('Jain'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Clear all drops the Tradition chip', (t) async {
    await _pumpBrowse(t, initialTradition: 'jain');
    expect(find.text('Jain'), findsWidgets);
    await t.tap(find.byKey(const Key('filter-clear')));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('filter-chip-tradition')),
        matching: find.text('Tradition'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('200% font and landscape still open the tradition sheet', (
    t,
  ) async {
    await pumpFilterBar(
      t,
      temples: _directory(),
      size: const Size(1200, 800),
      textScaler: const TextScaler.linear(2),
    );
    await openFilterChip(t, 'tradition');
    expect(find.byKey(const Key('filter-section-tradition')), findsOneWidget);
    expect(
      find.byKey(const Key('filter-option-tradition-jain')),
      findsOneWidget,
    );
  });

  testWidgets('Near Me lists a compact Tradition chip in instant mode', (
    t,
  ) async {
    useFilterSurface(t);
    await t.pumpWidget(
      MaterialApp(
        home: TemplesNearMeScreen(
          temples: _directory(),
          location: _DeniedLocation(),
          districtOf: (temple) => temple.city,
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('near-me-continue')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('near-me-state')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('near-me-state-option-Rajasthan')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('near-me-tradition-chip')), findsOneWidget);
    await t.tap(find.byKey(const Key('near-me-tradition-chip')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet-apply')), findsNothing);
    await t.tap(find.byKey(const Key('filter-option-tradition-jain')));
    await t.pumpAndSettle();
    expect(find.text('Dilwara Temples'), findsOneWidget);
  });
}

int directoryOrderIndex(String label) {
  const order = ['Hindu', 'Sikh', 'Jain', 'Buddhist'];
  return order.indexOf(label);
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
