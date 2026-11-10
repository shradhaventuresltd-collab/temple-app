import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'filter_sheet_support.dart';

void main() {
  testWidgets('filter_sheet_large_font_test', (tester) async {
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
    await pumpFilterBar(
      tester,
      temples: temples,
      size: const Size(360, 800),
      textScaler: const TextScaler.linear(2),
    );
    expect(tester.takeException(), isNull);
    final chip = tester.getSize(find.byKey(const Key('filter-chip-state')));
    expect(chip.height, greaterThanOrEqualTo(48));

    await openFilterChip(tester, 'state');
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('filter-sheet-footer-stack')), findsOneWidget);
    final apply = tester.getSize(find.byKey(const Key('filter-sheet-apply')));
    final clear = tester.getSize(find.byKey(const Key('filter-sheet-clear')));
    expect(apply.height, greaterThanOrEqualTo(48));
    expect(clear.height, greaterThanOrEqualTo(48));
    final row = tester.getSize(find.byKey(const Key('filter-option-state-Kerala')));
    expect(row.height, greaterThanOrEqualTo(48));
    expect(find.byKey(const Key('filter-sheet-apply')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
