import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/utils/temple_search.dart';
import 'package:temple_app/widgets/place_type_icon.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

import 'filter_sheet_support.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  String? cityAsDistrict(Temple temple) => temple.city;

  final meenakshi = filterTemple(
    name: 'Meenakshi Amman Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Devi',
  );
  final vaikom = filterTemple(
    name: 'Vaikom Mahadeva Temple',
    state: 'Kerala',
    city: 'Vaikom',
    deity: 'Shiva',
  );
  final harmandir = filterTemple(
    name: 'Harmandir Sahib',
    state: 'Punjab',
    city: 'Amritsar',
    deity: 'Guru Granth Sahib',
    tradition: 'sikh',
  );
  final dilwara = filterTemple(
    name: 'Dilwara Temples',
    state: 'Rajasthan',
    city: 'Mount Abu',
    deity: 'Rishabhanatha',
    tradition: 'jain',
  );
  final listed = [meenakshi, vaikom, harmandir, dilwara];

  test('tradition combines with state, district, deity, and all three', () {
    expect(
      directoryMatchingTemples(listed, tradition: 'sikh').map((t) => t.name),
      ['Harmandir Sahib'],
    );
    expect(
      directoryMatchingTemples(
        listed,
        tradition: 'hindu',
        state: 'Tamil Nadu',
      ).map((t) => t.name),
      ['Meenakshi Amman Temple'],
    );
    expect(
      directoryMatchingTemples(
        listed,
        tradition: 'jain',
        state: 'Rajasthan',
        district: 'Mount Abu',
        districtOf: cityAsDistrict,
      ).map((t) => t.name),
      ['Dilwara Temples'],
    );
    expect(
      directoryMatchingTemples(
        listed,
        tradition: 'hindu',
        deity: 'Shiva',
      ).map((t) => t.name),
      ['Vaikom Mahadeva Temple'],
    );
    expect(
      directoryMatchingTemples(
        listed,
        tradition: 'hindu',
        state: 'Tamil Nadu',
        deity: 'Devi',
        district: 'Madurai',
        districtOf: cityAsDistrict,
      ).map((t) => t.name),
      ['Meenakshi Amman Temple'],
    );
    expect(
      directoryMatchingTemples(
        listed,
        tradition: 'sikh',
        state: 'Tamil Nadu',
        deity: 'Devi',
        district: 'Madurai',
        districtOf: cityAsDistrict,
      ),
      isEmpty,
    );
  });

  test('places wording helpers', () {
    expect(directoryBrowseTitle(), 'All places');
    expect(directoryBrowseTitle(tradition: 'sikh', state: 'Punjab'), 'Punjab');
    expect(directoryPlaceCountLabel(0), '0 places');
    expect(directoryPlaceCountLabel(1), '1 place');
    expect(directoryPlaceCountLabel(3), '3 places');
    expect(directoryFilterResultLabel(1), 'Show 1 place');
    expect(directoryFilterResultLabel(3), 'Show 3 places');
    expect(
      directoryEmptyFilterMessage(district: 'Madurai', tradition: 'sikh'),
      'Nothing in the loaded directory fits these filters.',
    );
  });

  test('search synonyms map to tradition, including plurals and spacing', () {
    expect(templeMatchesQuery(harmandir, 'gurdwara'), isTrue);
    expect(templeMatchesQuery(harmandir, 'Gurudwara'), isTrue);
    expect(templeMatchesQuery(harmandir, 'GURDWARAS'), isTrue);
    expect(templeMatchesQuery(harmandir, 'guru dwara'), isTrue);
    expect(templeMatchesQuery(dilwara, 'derasar'), isTrue);
    expect(templeMatchesQuery(dilwara, 'Basadi'), isTrue);
    expect(templeMatchesQuery(dilwara, 'basadis'), isTrue);
    expect(templeMatchesQuery(meenakshi, 'gurdwara'), isFalse);
    expect(templeMatchesQuery(meenakshi, 'derasar'), isFalse);
    expect(templeMatchesQuery(vaikom, 'basadi'), isFalse);
    expect(
      filterTemples(listed, query: 'gurudwara').single.name,
      'Harmandir Sahib',
    );
    expect(
      filterTemples(listed, query: 'derasar').single.name,
      'Dilwara Temples',
    );
  });

  testWidgets('re-opening the Tradition sheet keeps the selection', (
    tester,
  ) async {
    await pumpFilterBar(tester, temples: listed, districtOf: cityAsDistrict);
    await openFilterChip(tester, 'tradition');
    await chooseAndApply(tester, const Key('filter-option-tradition-sikh'));
    expect(find.text('Sikh'), findsOneWidget);
    expect(find.text('Harmandir Sahib'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);

    await openFilterChip(tester, 'tradition');
    expect(find.byKey(const Key('filter-section-tradition')), findsOneWidget);
    expect(
      find.byKey(const Key('filter-option-tradition-sikh')),
      findsOneWidget,
    );
    expect(find.text('Show 1 place'), findsOneWidget);
    await applyFilterSheet(tester);
    expect(find.text('Sikh'), findsOneWidget);
    expect(find.text('Harmandir Sahib'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);
  });

  testWidgets('tradition plus state, district, deity, then clear-all', (
    tester,
  ) async {
    await pumpFilterBar(tester, temples: listed, districtOf: cityAsDistrict);

    await openFilterChip(tester, 'tradition');
    await chooseAndApply(tester, const Key('filter-option-tradition-hindu'));
    await openFilterChip(tester, 'state');
    await chooseAndApply(tester, const Key('filter-option-state-Tamil Nadu'));
    await openFilterChip(tester, 'district');
    await chooseAndApply(tester, const Key('filter-option-district-Madurai'));
    await openFilterChip(tester, 'deity');
    await chooseAndApply(tester, const Key('filter-option-deity-Devi'));

    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Harmandir Sahib'), findsNothing);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);
    expect(find.text('1 place'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Tradition'), findsOneWidget);
    expect(find.text('State'), findsOneWidget);
    expect(find.text('Harmandir Sahib'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('4 places'), findsOneWidget);
  });


  testWidgets('cards and detail show gurdwara and derasar type icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              TempleBrowseCard(temple: harmandir),
              TempleBrowseCard(temple: dilwara),
              TempleBrowseCard(temple: meenakshi),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('browse-place-type-icon')), findsNWidgets(2));
    expect(find.bySemanticsLabel('Gurdwara'), findsOneWidget);
    expect(find.bySemanticsLabel('Derasar'), findsOneWidget);
    expect(placeTypeKindOf(harmandir), PlaceTypeKind.sikhGurdwara);
    expect(placeTypeKindOf(dilwara), PlaceTypeKind.jainDerasar);
    expect(placeTypeKindOf(meenakshi), PlaceTypeKind.hindu);
  });
}
