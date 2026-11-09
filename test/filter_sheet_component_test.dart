import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/widgets/filter_sheet.dart';

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

  testWidgets('filter_sheet_component_test', (tester) async {
    await pumpFilterBar(tester, temples: temples);
    await openFilterChip(tester, 'state');

    expect(find.byKey(const Key('filter-sheet-title')), findsOneWidget);
    expect(find.text('State'), findsWidgets);
    expect(find.byKey(const Key('filter-sheet-close')), findsOneWidget);
    expect(find.byKey(const Key('filter-sheet-apply')), findsOneWidget);
    expect(find.byKey(const Key('filter-sheet-clear')), findsOneWidget);
    expect(find.byKey(const Key('filter-sheet-apply')).hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('filter-sheet-clear')).hitTestable(), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-option-state-Kerala')));
    await tester.pump();
    expect(find.text('Show 1 temple'), findsOneWidget);
    expect(find.byKey(const Key('filter-sheet-apply')).hitTestable(), findsOneWidget);

    tester.view.physicalSize = const Size(900, 500);
    await tester.pumpAndSettle();
    expect(find.text('Kerala'), findsWidgets);
    expect(find.byKey(const Key('filter-sheet-apply')).hitTestable(), findsOneWidget);
    expect(find.text('Show 1 temple'), findsOneWidget);
  });

  testWidgets('instant mode commits on tap and has no apply footer', (
    tester,
  ) async {
    useFilterSurface(tester);
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  final colors = FilterSheetColors.of(context);
                  picked = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    enableDrag: false,
                    backgroundColor: colors.sheetBackground,
                    builder: (context) {
                      return FilterSheetScaffold(
                        title: 'City',
                        sectionKey: const Key('near-me-city-sheet'),
                        mode: FilterSheetMode.instant,
                        any: const FilterSheetOption(
                          id: 'near-me-city-option-any',
                          label: 'Any city',
                          count: 2,
                          value: '',
                        ),
                        sections: const [
                          FilterSheetSection(
                            id: 'cities',
                            title: '',
                            options: [
                              FilterSheetOption(
                                id: 'near-me-city-option-Kochi',
                                label: 'Kochi',
                                count: 1,
                                value: 'Kochi',
                              ),
                            ],
                          ),
                        ],
                        onOption: (option) =>
                            Navigator.pop(context, option.value),
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet-apply')), findsNothing);
    expect(find.byKey(const Key('filter-sheet-title')), findsOneWidget);
    await tester.tap(find.byKey(const Key('near-me-city-option-Kochi')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
    expect(picked, 'Kochi');
  });
}
