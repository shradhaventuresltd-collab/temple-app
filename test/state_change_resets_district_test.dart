import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'filter_sheet_support.dart';

void main() {
  String? districtOf(temple) => temple.city as String;

  testWidgets('state_change_resets_district_test', (tester) async {
    final temples = [
      filterTemple(
        name: 'Meenakshi Amman Temple',
        state: 'Tamil Nadu',
        city: 'Madurai',
        deity: 'Devi',
      ),
      filterTemple(
        name: 'Vaikom Mahadeva Temple',
        state: 'Kerala',
        city: 'Kottayam',
        deity: 'Shiva',
      ),
      filterTemple(
        name: 'Shared Tamil',
        state: 'Tamil Nadu',
        city: 'Shared',
        deity: 'Shiva',
      ),
      filterTemple(
        name: 'Shared Kerala',
        state: 'Kerala',
        city: 'Shared',
        deity: 'Shiva',
      ),
    ];
    await pumpFilterBar(tester, temples: temples, districtOf: districtOf);

    await openFilterChip(tester, 'state');
    await chooseAndApply(tester, const Key('filter-option-state-Tamil Nadu'));
    await openFilterChip(tester, 'district');
    await chooseAndApply(tester, const Key('filter-option-district-Madurai'));
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Shared Kerala'), findsNothing);

    await openFilterChip(tester, 'state');
    await chooseAndApply(tester, const Key('filter-option-state-Kerala'));
    expect(find.text('Madurai'), findsNothing);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Shared Kerala'), findsOneWidget);

    await openFilterChip(tester, 'district');
    await chooseAndApply(tester, const Key('filter-option-district-Shared'));
    expect(find.text('Shared Kerala'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);

    await openFilterChip(tester, 'state');
    await chooseAndApply(tester, const Key('filter-option-state-Tamil Nadu'));
    expect(find.text('Shared Tamil'), findsOneWidget);
    expect(find.text('Shared Kerala'), findsNothing);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);
  });
}
