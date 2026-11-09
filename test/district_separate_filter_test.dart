import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'filter_sheet_support.dart';

void main() {
  String? districtOf(temple) {
    return switch (temple.city as String) {
      'Madurai' => 'Madurai',
      'Kottayam' => 'Kottayam',
      'Mahabalipuram' => 'Chengalpattu',
      _ => 'District ${temple.city}',
    };
  }

  final temples = [
    filterTemple(
      name: 'Meenakshi Amman Temple',
      state: 'Tamil Nadu',
      city: 'Madurai',
      deity: 'Devi',
    ),
    filterTemple(
      name: 'Shore Temple',
      state: 'Tamil Nadu',
      city: 'Mahabalipuram',
      deity: 'Shiva',
      latitude: 12.6,
      longitude: 80.1,
    ),
    filterTemple(
      name: 'Vaikom Mahadeva Temple',
      state: 'Kerala',
      city: 'Kottayam',
      deity: 'Shiva',
    ),
  ];

  testWidgets('district_separate_filter_test', (tester) async {
    final many = [
      for (var i = 0; i < 16; i++)
        filterTemple(
          name: 'Kerala $i',
          state: 'Kerala',
          city: 'District $i',
          deity: 'Shiva',
        ),
      ...temples,
    ];
    await pumpFilterBar(tester, temples: many, districtOf: districtOf);
    await openFilterChip(tester, 'district');
    expect(find.byKey(const Key('filter-choose-state-first')), findsOneWidget);
    expect(find.byKey(const Key('filter-option-district-Madurai')), findsNothing);
    expect(find.byKey(const Key('filter-section-state')), findsOneWidget);

    await chooseAndApply(tester, const Key('filter-option-state-Kerala'));
    expect(find.byKey(const Key('filter-section-district')), findsOneWidget);
    expect(find.text('In Kerala · '), findsOneWidget);
    expect(find.byKey(const Key('filter-change-state')), findsOneWidget);
    expect(find.text('All districts in Kerala'), findsOneWidget);
    expect(find.byKey(const Key('filter-option-district-Kottayam')), findsOneWidget);
    expect(find.byKey(const Key('filter-option-district-Madurai')), findsNothing);
    expect(find.byKey(const Key('filter-option-state-Tamil Nadu')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('filter-sheet-search')),
      'no-such-district',
    );
    await tester.pump();
    expect(find.byKey(const Key('filter-sheet-no-match')), findsOneWidget);
  });
}
