import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'filter_sheet_support.dart';

void main() {
  testWidgets('clear_all_resets_all_test', (tester) async {
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
    String? districtOf(temple) => temple.city as String;
    await pumpFilterBar(tester, temples: temples, districtOf: districtOf);

    expect(find.text('3 places'), findsOneWidget);
    await openFilterChip(tester, 'state');
    await chooseAndApply(tester, const Key('filter-option-state-Tamil Nadu'));
    await openFilterChip(tester, 'district');
    await chooseAndApply(tester, const Key('filter-option-district-Madurai'));
    await openFilterChip(tester, 'deity');
    await chooseAndApply(tester, const Key('filter-option-deity-Devi'));

    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Shore Temple'), findsNothing);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);
    expect(find.text('1 place'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Shore Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('3 places'), findsOneWidget);
    expect(find.byKey(const Key('filter-clear')), findsNothing);
    expect(find.text('State'), findsWidgets);
    expect(find.text('District'), findsWidgets);
    expect(find.text('Deity'), findsWidgets);
  });
}
