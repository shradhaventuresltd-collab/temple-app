import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'filter_sheet_support.dart';

void main() {
  final temples = [
    filterTemple(
      name: 'Vaikom Mahadeva Temple',
      state: 'Kerala',
      city: 'Kottayam',
      deity: 'Shiva',
    ),
    filterTemple(
      name: 'Meenakshi Amman Temple',
      state: 'Tamil Nadu',
      city: 'Madurai',
      deity: 'Devi',
    ),
  ];

  testWidgets('chip_double_tap_single_sheet_test', (tester) async {
    await pumpFilterBar(tester, temples: temples);
    await tester.tap(find.byKey(const Key('filter-chip-state')));
    await tester.tap(
      find.byKey(const Key('filter-chip-state')),
      warnIfMissed: false,
    );
    await tester.tap(
      find.byKey(const Key('filter-chip-deity')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-section-state')), findsOneWidget);
    expect(find.byKey(const Key('filter-section-deity')), findsNothing);

    final kerala = find.byKey(const Key('filter-option-state-Kerala'));
    await tester.ensureVisible(kerala);
    await tester.tap(kerala);
    await tester.pump();
    await tester.tap(kerala);
    await tester.pump();
    expect(find.text('Show 1 place'), findsOneWidget);
    await applyFilterSheet(tester);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);
  });
}
