// KAN-203 deity sheet scoping and tradition resolution order.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/widgets/app_drawer.dart';

import 'filter_sheet_support.dart';

final shiva = filterTemple(
  name: 'Vaikom Mahadeva Temple',
  state: 'Kerala',
  city: 'Vaikom',
  deity: 'Shiva',
);
final dilwara = filterTemple(
  name: 'Dilwara Temples',
  state: 'Rajasthan',
  city: 'Mount Abu',
  deity: 'Rishabhanatha',
  tradition: 'jain',
);
final harmandir = Temple(
  name: 'Harmandir Sahib',
  state: 'Punjab',
  city: 'Amritsar',
  deity: 'Guru Granth Sahib',
  imageUrl: '',
  description: '',
  story: '',
  location: 'Amritsar, Punjab',
  timings: '',
  specialities: const [],
  latitude: 31.62,
  longitude: 74.88,
  tradition: 'jain',
  indexTradition: 'sikh',
);

List<Temple> get listed => [shiva, dilwara, harmandir];

Future<void> _pump(
  WidgetTester t, {
  String? tradition,
  String? deity,
  String? state,
}) async {
  useFilterSurface(t);
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TempleBrowseList(
          temples: listed,
          initialTradition: tradition,
          initialDeity: deity,
          initialState: state,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test(
    'indexTradition wins over the document field, then deity, then Hindu',
    () {
      expect(directoryTraditionKey(harmandir), 'sikh');
      expect(
        directoryTraditionKey(
          filterTemple(
            name: 'Local shrine',
            state: 'Kerala',
            city: 'Vaikom',
            deity: 'Shiva',
          ),
        ),
        'hindu',
      );
      expect(directoryTraditionKey(dilwara), 'jain');
      expect(directoryTraditionOrder, ['hindu', 'sikh', 'jain', 'buddhist']);
    },
  );

  testWidgets('deity list is scoped by the selected tradition', (t) async {
    await _pump(t, tradition: 'jain');
    await t.ensureVisible(find.byKey(const Key('filter-chip-deity')));
    await t.tap(find.byKey(const Key('filter-chip-deity')));
    await t.pumpAndSettle();
    expect(find.text('Change tradition'), findsOneWidget);
    expect(find.textContaining('In Jain places'), findsOneWidget);
    expect(
      find.byKey(const Key('filter-option-deity-Rishabhanatha')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('filter-option-deity-Shiva')), findsNothing);
  });

  testWidgets('Change tradition re-opens the Tradition sheet', (t) async {
    await _pump(t, tradition: 'jain');
    await t.tap(find.byKey(const Key('filter-chip-deity')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('filter-change-tradition')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('filter-section-tradition')), findsOneWidget);
  });

  testWidgets('selecting a tradition that excludes the deity clears Deity', (
    t,
  ) async {
    await _pump(t, deity: 'Shiva');
    expect(
      find.descendant(
        of: find.byKey(const Key('filter-chip-deity')),
        matching: find.textContaining('Shiva'),
      ),
      findsOneWidget,
    );
    await t.ensureVisible(find.byKey(const Key('filter-chip-tradition')));
    await t.tap(find.byKey(const Key('filter-chip-tradition')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('filter-option-tradition-jain')));
    await t.tap(find.byKey(const Key('filter-sheet-apply')));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('filter-chip-deity')),
        matching: find.text('Deity'),
      ),
      findsOneWidget,
    );
    expect(find.text('Dilwara Temples'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);
  });

  test('Tradition + Deity + State census uses the same resolution', () {
    final matches = directoryMatchingTemples(
      listed,
      tradition: 'sikh',
      state: 'Punjab',
      deity: 'Guru Granth Sahib',
    );
    expect(matches.map((t) => t.name), ['Harmandir Sahib']);
    expect(
      directoryMatchingTemples(listed, tradition: 'hindu').map((t) => t.name),
      ['Vaikom Mahadeva Temple'],
    );
  });
}
