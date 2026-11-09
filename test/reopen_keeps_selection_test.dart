import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/widgets/filter_sheet_theme.dart';

import 'filter_sheet_support.dart';

void main() {
  testWidgets('reopen_keeps_selection_test', (tester) async {
    final temples = [
      for (final state in [
        'Chandigarh',
        'Delhi',
        'Haryana',
        'Himachal Pradesh',
        'Jammu and Kashmir',
        'Ladakh',
        'Punjab',
        'Uttar Pradesh',
        'Uttarakhand',
      ])
        filterTemple(name: state, state: state, city: state, deity: 'Shiva'),
      filterTemple(
        name: 'Vaikom Mahadeva Temple',
        state: 'Kerala',
        city: 'Kottayam',
        deity: 'Shiva',
      ),
    ];
    await pumpFilterBar(
      tester,
      temples: temples,
      size: const Size(360, 640),
    );
    await openFilterChip(tester, 'state');
    expect(find.text('SOUTH'), findsOneWidget);
    expect(find.text('Kerala'), findsWidgets);
    expect(
      find.byKey(const Key('filter-option-state-Kerala')).hitTestable(),
      findsNothing,
    );
    await chooseAndApply(tester, const Key('filter-option-state-Kerala'));
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);

    await openFilterChip(tester, 'state');
    expect(
      find.byKey(const Key('filter-option-state-Kerala')).hitTestable(),
      findsOneWidget,
    );
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(const Key('filter-option-state-Kerala')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, FilterSheetColors.light.selectedRow);
  });
}
