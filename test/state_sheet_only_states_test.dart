import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/temple.dart';

import 'filter_sheet_support.dart';

void main() {
  testWidgets('state_sheet_only_states_test', (tester) async {
    final temples = [
      for (var i = 0; i < 12; i++)
        filterTemple(
          name: 'North $i',
          state: [
            'Chandigarh',
            'Delhi',
            'Haryana',
            'Himachal Pradesh',
            'Punjab',
            'Uttar Pradesh',
          ][i % 6],
          city: 'City $i',
          deity: 'Shiva',
        ),
      filterTemple(
        name: 'Vaikom Mahadeva Temple',
        state: 'Kerala',
        city: 'Kottayam',
        deity: 'Shiva',
      ),
      filterTemple(
        name: 'Shore Temple',
        state: 'Tamil Nadu',
        city: 'Mahabalipuram',
        deity: 'Shiva',
        latitude: 12.6,
        longitude: 80.1,
      ),
    ];
    String? districtOf(Temple temple) => temple.city;

    await pumpFilterBar(tester, temples: temples, districtOf: districtOf);
    await openFilterChip(tester, 'state');

    expect(find.byKey(const Key('filter-section-state')), findsOneWidget);
    expect(find.text('NORTH'), findsOneWidget);
    expect(find.text('SOUTH'), findsOneWidget);
    expect(find.byKey(const Key('filter-option-district-any')), findsNothing);
    expect(find.byKey(const Key('filter-option-deity-any')), findsNothing);
    expect(find.byKey(const Key('filter-section-district')), findsNothing);
    expect(find.byKey(const Key('filter-section-deity')), findsNothing);

    await tester.drag(
      find.byKey(const Key('filter-sheet-options')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-option-district-any')), findsNothing);
    expect(find.byKey(const Key('filter-option-deity-Shiva')), findsNothing);

    await tester.enterText(find.byKey(const Key('filter-sheet-search')), 'kera');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-option-state-Kerala')), findsOneWidget);
    expect(find.byKey(const Key('filter-option-state-Delhi')), findsNothing);
    expect(find.text('SOUTH'), findsOneWidget);
    expect(find.text('NORTH'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('filter-sheet-search')),
      'zzzz-no-state',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet-no-match')), findsOneWidget);
  });
}
