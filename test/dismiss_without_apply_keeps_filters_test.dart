import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'filter_sheet_support.dart';

void main() {
  testWidgets('dismiss_without_apply_keeps_filters_test', (tester) async {
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
    await pumpFilterBar(tester, temples: temples, initialState: 'Tamil Nadu');
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);

    await openFilterChip(tester, 'state');
    await tester.ensureVisible(find.byKey(const Key('filter-option-state-Kerala')));
    await tester.tap(find.byKey(const Key('filter-option-state-Kerala')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);

    await openFilterChip(tester, 'state');
    await tester.tap(find.byKey(const Key('filter-sheet-title')));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);

    await openFilterChip(tester, 'deity');
    await tester.tap(find.byKey(const Key('filter-option-deity-Devi')));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('filter-sheet-title')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);
  });
}
