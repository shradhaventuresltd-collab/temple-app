import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/widgets/directory_filter_bar.dart';

Temple _t(String n, String s, String d) => Temple(
  name: n,
  state: s,
  city: 'C',
  deity: d,
  imageUrl: '',
  description: '',
  story: '',
  location: 'C, $s',
  timings: '',
  specialities: const [],
  latitude: 10,
  longitude: 78,
);

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final temples = [
    for (var i = 0; i < 40; i++)
      _t('T$i', 'State ${String.fromCharCode(65 + i % 26)}$i', 'Deity$i'),
  ];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DirectoryFilterBar(
          temples: temples,
          selectedState: null,
          selectedDeity: null,
          selectedDistrict: null,
          districtOf: (t) => t.city,
          onChanged: (_, _, _) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('filter-chip-state')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
}

// The emulator's swipe-dismiss (tool/emulator/lib/common.sh,
// dismiss_sheet_from_handle) pulls from the 'Filters' title at 320x640.
// The sheet closes on PointerMove travel only: a down/up with no move in
// between leaves it open, any delivered move past 72px closes it.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  // (name, number of move events between down and up)
  for (final moves in [0, 1, 2, 5, 20]) {
    testWidgets('header pull with $moves moves', (tester) async {
      await _open(tester);
      final start = tester.getCenter(find.byKey(const Key('filter-sheet-title')));
      const end = 614.0;
      final g = await tester.startGesture(start);
      for (var i = 1; i <= moves; i++) {
        await g.moveTo(
          Offset(start.dx, start.dy + (end - start.dy) * i / moves),
        );
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('filter-sheet')),
        moves == 0 ? findsOneWidget : findsNothing,
      );
    });
  }

  // Ported from #124 v4 (lib/widgets/directory_filter_bar.dart ignores
  // dy == 0): `adb shell input swipe` can repeat the down point as its first
  // move. That move must not disarm the pull.
  testWidgets('first move repeating the down point still dismisses', (
    tester,
  ) async {
    await _open(tester);
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('filter-sheet-title'))));
    await g.moveBy(Offset.zero);
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await g.moveBy(const Offset(0, 30));
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
  });

  testWidgets('a real 72px drag closes the sheet', (tester) async {
    await _open(tester);
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('filter-sheet-title'))));
    await g.moveBy(Offset.zero);
    await g.moveBy(const Offset(0, 36));
    await g.moveBy(const Offset(0, 36));
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
  });

  testWidgets('a 71px drag leaves the sheet open', (tester) async {
    await _open(tester);
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('filter-sheet-title'))));
    await g.moveBy(const Offset(0, 71));
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
  });

  testWidgets('an upward move still disarms the pull', (tester) async {
    await _open(tester);
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('filter-sheet-title'))));
    await g.moveBy(const Offset(0, -5));
    await g.moveBy(const Offset(0, 120));
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
  });

  // KAN-192: vertical travel must dominate. A mostly sideways drag that
  // also travels 72px down is not a pull and must leave the sheet open.
  testWidgets('200px sideways / 72px down leaves the sheet open', (
    tester,
  ) async {
    await _open(tester);
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('filter-sheet-title'))));
    for (var i = 0; i < 4; i++) {
      await g.moveBy(const Offset(50, 18));
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
  });
}
