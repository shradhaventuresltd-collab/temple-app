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

  testWidgets('state sheet region headers stay pinned', (tester) async {
    const north = [
      'Chandigarh',
      'Delhi',
      'Haryana',
      'Himachal Pradesh',
      'Jammu and Kashmir',
      'Ladakh',
      'Punjab',
      'Uttar Pradesh',
      'Uttarakhand',
    ];
    const south = [
      'Andhra Pradesh',
      'Karnataka',
      'Kerala',
      'Puducherry',
      'Tamil Nadu',
      'Telangana',
    ];
    final temples = [
      for (var i = 0; i < north.length; i++)
        filterTemple(
          name: 'North $i',
          state: north[i],
          city: 'City $i',
          deity: 'Shiva',
        ),
      for (var i = 0; i < south.length; i++)
        filterTemple(
          name: 'South $i',
          state: south[i],
          city: 'Town $i',
          deity: 'Shiva',
        ),
    ];
    await pumpFilterBar(
      tester,
      temples: temples,
      size: const Size(400, 560),
    );
    await openFilterChip(tester, 'state');
    final scrollable = find.descendant(
      of: find.byKey(const Key('filter-sheet-options')),
      matching: find.byType(Scrollable),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('filter-option-state-Uttarakhand')),
      40,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    final listTop = tester.getTopLeft(find.byKey(const Key('filter-sheet-options'))).dy;
    expect(find.text('NORTH'), findsOneWidget);
    final northDy = tester.getTopLeft(find.text('NORTH')).dy;
    expect(northDy, inInclusiveRange(listTop, listTop + 16));
    expect(
      find.byKey(const Key('filter-option-state-Uttarakhand')).hitTestable(),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('filter-option-state-Telangana')),
      80,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('SOUTH'), findsOneWidget);
    final southDy = tester.getTopLeft(find.text('SOUTH')).dy;
    expect(southDy, inInclusiveRange(listTop, listTop + 16));
    expect(tester.getTopLeft(find.text('NORTH')).dy, lessThan(listTop));
    expect(
      find.byKey(const Key('filter-option-state-Telangana')).hitTestable(),
      findsOneWidget,
    );
  });
}
