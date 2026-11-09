import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/utils/deity_groups.dart';
import 'package:temple_app/utils/directory_filters.dart';

import 'filter_sheet_support.dart';

void main() {
  test('deity grouping folds parentheses, case, and whitespace', () {
    final groups = groupDeityNames([
      'Shiva',
      'Shiva (Gangadhareshwara)',
      '  shiva  ',
      'SHIVA',
      'Devi(Kamakshi)',
      '  Devi   (Meenakshi)  ',
    ]);
    expect(groups.map((group) => group.label), ['Devi', 'Shiva']);
    final shiva = groups.singleWhere((group) => group.label == 'Shiva');
    expect(shiva.variants, hasLength(4));
    expect(deityGroupKey(' Shiva (Gangadhareshwara) '), deityGroupKey('shiva'));
    expect(deityGroupMatches('Shiva (Gangadhareshwara)', 'Shiva'), isTrue);
    expect(deityGroupMatches('Devi (Meenakshi)', 'Shiva'), isFalse);
    expect(deityGroupMatches('Shiva', null), isTrue);
  });

  test('deity grouping cuts on parenthesis, em dash, and comma', () {
    expect(deityGroupBase('Shiva — Gangadhareshwara'), 'Shiva');
    expect(deityGroupBase('Shiva, Gangadhareshwara'), 'Shiva');
    expect(deityGroupBase('Shiva (Gangadhareshwara)'), 'Shiva');
    expect(deityGroupBase('Venkateswara'), 'Venkateswara');
    expect(deityGroupBase('Shiva, Lord (form) — extra'), 'Shiva');
    expect(deityGroupBase('Shiva (form), extra — more'), 'Shiva');
    expect(deityGroupBase('Shiva — form, extra (more)'), 'Shiva');

    final groups = groupDeityNames([
      'Shiva — Gangadhareshwara',
      '  SHIVA,  Gangadhareshwara  ',
      'shiva (gangadhareshwara)',
      '  shiva  ',
      'Venkateswara',
    ]);
    expect(groups.map((group) => group.label), ['Shiva', 'Venkateswara']);
    final shiva = groups.singleWhere((group) => group.label == 'Shiva');
    expect(shiva.variants, hasLength(4));
    expect(
      deityGroupKey('SHIVA — GANGADHARESHWARA'),
      deityGroupKey('  shiva, gangadhareshwara '),
    );
    expect(deityGroupMatches('Shiva — Gangadhareshwara', 'Shiva'), isTrue);
    expect(deityGroupMatches('Shiva, Gangadhareshwara', 'shiva'), isTrue);
    expect(deityGroupMatches('Venkateswara', 'Shiva'), isFalse);
  });

  testWidgets('deity_sheet_grouping_search_test', (tester) async {
    final temples = [
      filterTemple(
        name: 'Gangadhareshwara',
        state: 'Karnataka',
        city: 'Bengaluru',
        deity: 'Shiva (Gangadhareshwara)',
      ),
      filterTemple(
        name: 'Somnath Temple',
        state: 'Gujarat',
        city: 'Veraval',
        deity: 'Shiva',
        latitude: 20.88,
        longitude: 70.4,
      ),
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
        deity: ' shiva ',
      ),
      for (var i = 0; i < 8; i++)
        filterTemple(
          name: 'Other $i',
          state: 'Kerala',
          city: 'City $i',
          deity: 'Deity $i',
        ),
    ];
    String? districtOf(temple) => temple.city == 'Madurai' ? 'Madurai' : 'Ernakulam';

    await pumpFilterBar(tester, temples: temples, districtOf: districtOf);
    await openFilterChip(tester, 'deity');
    expect(find.text('MOST LISTED'), findsOneWidget);
    expect(find.byKey(const Key('filter-option-deity-Shiva')), findsOneWidget);
    expect(
      find.byKey(const Key('filter-option-deity-Shiva (Gangadhareshwara)')),
      findsNothing,
    );

    await tester.enterText(find.byKey(const Key('filter-sheet-search')), 'ganga');
    await tester.pump();
    expect(find.byKey(const Key('filter-option-deity-Shiva')), findsOneWidget);
    expect(find.byKey(const Key('filter-option-deity-Devi')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('filter-sheet-search')),
      'no-such-deity',
    );
    await tester.pump();
    expect(find.byKey(const Key('filter-sheet-no-match')), findsOneWidget);
    expect(find.text('No match for \u2018no-such-deity\u2019'), findsOneWidget);
    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();

    await openFilterChip(tester, 'deity');
    await chooseAndApply(tester, const Key('filter-option-deity-Shiva'));
    expect(find.text('Gangadhareshwara'), findsOneWidget);
    expect(find.text('Somnath Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);

    await openFilterChip(tester, 'deity');
    expect(find.byKey(const Key('filter-option-deity-Shiva')), findsOneWidget);
    final selected = tester.widget<InkWell>(
      find.byKey(const Key('filter-option-deity-Shiva')),
    );
    expect(selected.onTap, isNotNull);
    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filter-clear')));
    await tester.pumpAndSettle();
    await openFilterChip(tester, 'state');
    await chooseAndApply(tester, const Key('filter-option-state-Tamil Nadu'));
    await openFilterChip(tester, 'district');
    await chooseAndApply(tester, const Key('filter-option-district-Madurai'));
    await openFilterChip(tester, 'deity');
    expect(find.byKey(const Key('filter-option-deity-Devi')), findsOneWidget);
    expect(find.byKey(const Key('filter-option-deity-Shiva')), findsNothing);
    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();

    final hidden = directoryMatchingTemples(
      temples,
      state: 'Tamil Nadu',
      district: 'Madurai',
      deity: 'Shiva',
      districtOf: (temple) => temple.city == 'Madurai' ? 'Madurai' : 'Ernakulam',
    );
    expect(hidden, isEmpty);
  });

  testWidgets('deity rows are built lazily', (tester) async {
    final temples = [
      for (var i = 0; i < 40; i++)
        filterTemple(
          name: 'Temple $i',
          state: 'Kerala',
          city: 'City $i',
          deity: 'Deity ${i.toString().padLeft(2, '0')}',
        ),
    ];
    await pumpFilterBar(tester, temples: temples, size: const Size(400, 640));
    await openFilterChip(tester, 'deity');
    final built = find
        .byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              ((widget.key! as ValueKey<String>).value.startsWith(
                    'filter-option-deity-',
                  ) ||
                  (widget.key! as ValueKey<String>).value.startsWith(
                    'filter-deity-top-',
                  )),
        )
        .evaluate()
        .length;
    expect(built, greaterThan(0));
    expect(built, lessThan(30));
  });
}
