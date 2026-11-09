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
    final sheet = tester.getSize(find.byKey(const Key('filter-sheet')));
    expect(sheet.height, 1600 * 0.78);
    expect(sheet.width, 560);
    expect(find.text('State'), findsWidgets);
    expect(find.byKey(const Key('filter-sheet-close')), findsOneWidget);
    expect(find.byKey(const Key('filter-sheet-apply')), findsOneWidget);
    expect(find.byKey(const Key('filter-sheet-clear')), findsOneWidget);
    expect(
      find.byKey(const Key('filter-sheet-apply')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-sheet-clear')).hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('filter-option-state-Kerala')));
    await tester.pump();
    expect(find.text('Show 1 temple'), findsOneWidget);
    expect(
      find.byKey(const Key('filter-sheet-apply')).hitTestable(),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(900, 500);
    await tester.pumpAndSettle();
    final landscape = tester.getSize(find.byKey(const Key('filter-sheet')));
    expect(landscape.width, 560);
    expect(landscape.height, 500 * 0.78);
    expect(find.text('Kerala'), findsWidgets);
    expect(
      find.byKey(const Key('filter-sheet-apply')).hitTestable(),
      findsOneWidget,
    );
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

  testWidgets('a long chip label ellipsizes within 180dp', (tester) async {
    const label = 'Dadra and Nagar Haveli and Daman and Diu';
    await pumpFilterBar(
      tester,
      temples: [
        filterTemple(
          name: 'Temple',
          state: label,
          city: 'City',
          deity: 'Shiva',
        ),
      ],
      initialState: label,
    );
    final text = tester.widget<Text>(find.text(label));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.text(label)).width, lessThanOrEqualTo(180));
  });

  testWidgets('a tap above the sheet dismisses it', (tester) async {
    await pumpFilterBar(tester, temples: temples);
    await openFilterChip(tester, 'state');
    expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
    final sheetTop = tester
        .getTopLeft(find.byKey(const Key('filter-sheet')))
        .dy;
    expect(sheetTop, greaterThan(40));
    await tester.tapAt(const Offset(400, 20));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
  });

  testWidgets('Apply stays on screen in a short landscape sheet', (
    tester,
  ) async {
    const keyboard = 180.0;
    final many = [
      for (final state in [
        'Tamil Nadu',
        'Kerala',
        'Karnataka',
        'Andhra Pradesh',
        'Telangana',
        'Maharashtra',
        'Gujarat',
        'Rajasthan',
        'Delhi',
        'Punjab',
        'Uttar Pradesh',
        'Bihar',
        'West Bengal',
        'Odisha',
        'Assam',
        'Goa',
        'Haryana',
        'Madhya Pradesh',
        'Chhattisgarh',
        'Jharkhand',
        'Uttarakhand',
        'Himachal Pradesh',
        'Manipur',
        'Meghalaya',
        'Tripura',
      ])
        filterTemple(
          name: '$state temple',
          state: state,
          city: 'City',
          deity: 'Shiva',
        ),
    ];
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.resetViewInsets);
    await pumpFilterBar(
      tester,
      temples: many,
      size: const Size(900, 400),
      textScaler: const TextScaler.linear(1.3),
    );
    await openFilterChip(tester, 'state');
    await tester.enterText(find.byKey(const Key('filter-sheet-search')), 'Ker');
    await tester.pump();
    final apply = find.byKey(const Key('filter-sheet-apply'));
    expect(apply.hitTestable(), findsOneWidget);
    final rect = tester.getRect(apply);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.bottom, lessThanOrEqualTo(400 - keyboard));
    expect(find.byKey(const Key('filter-sheet-options')), findsOneWidget);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
  });

  testWidgets('a district picked with no state applies and reopens', (
    tester,
  ) async {
    String? districtOf(temple) => temple.city as String;
    await pumpFilterBar(tester, temples: temples, districtOf: districtOf);
    await tester.tap(find.byKey(const Key('filter-chip-district')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a state first'), findsOneWidget);
    await tester.tap(find.byKey(const Key('filter-option-state-Tamil Nadu')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('filter-sheet-apply')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-section-district')), findsOneWidget);
    await tester.tap(find.byKey(const Key('filter-option-district-Madurai')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('filter-sheet-apply')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
    expect(find.text('Tamil Nadu'), findsWidgets);
    expect(find.text('Madurai'), findsWidgets);
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-chip-district')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-section-district')), findsOneWidget);
    expect(find.text('Choose a state first'), findsNothing);
    expect(
      find.byKey(const Key('filter-option-district-Madurai')),
      findsOneWidget,
    );
    expect(find.text('Tamil Nadu'), findsWidgets);
  });

  testWidgets('each sheet title is its own semantics node', (tester) async {
    String? districtOf(temple) => temple.city as String;
    await pumpFilterBar(
      tester,
      temples: temples,
      initialState: 'Kerala',
      districtOf: districtOf,
    );
    for (final (:chip, :title) in [
      (chip: 'state', title: 'State'),
      (chip: 'district', title: 'District'),
      (chip: 'deity', title: 'Deity'),
    ]) {
      await openFilterChip(tester, chip);
      final id = filterSheetTitleId(title);
      final titleNode = tester.getSemantics(find.bySemanticsIdentifier(id));
      expect(titleNode.identifier, id);
      expect(titleNode.label, title);
      final sheetNode = tester.getSemantics(
        find.bySemanticsIdentifier('filter-sheet'),
      );
      expect(titleNode.id, isNot(sheetNode.id));
      expect(sheetNode.flagsCollection.isTextField, isFalse);
      expect(find.text(title), findsWidgets);
      await tester.tap(find.byKey(const Key('filter-sheet-close')));
      await tester.pumpAndSettle();
    }
  });
}
