// Tradition option counts must equal the list after applying that option.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';

import 'filter_sheet_support.dart';

Temple _t({
  required String name,
  required String state,
  required String city,
  required String deity,
  String? tradition,
}) {
  return filterTemple(
    name: name,
    state: state,
    city: city,
    deity: deity,
    tradition: tradition,
  );
}

final _listed = [
  _t(name: 'Shiva one', state: 'Punjab', city: 'Amritsar', deity: 'Shiva'),
  _t(name: 'Durga one', state: 'Punjab', city: 'Ludhiana', deity: 'Durga'),
  _t(name: 'Vishnu one', state: 'Punjab', city: 'Patiala', deity: 'Vishnu'),
  _t(
    name: 'Dilwara',
    state: 'Rajasthan',
    city: 'Mount Abu',
    deity: 'Rishabhanatha',
    tradition: 'jain',
  ),
  _t(
    name: 'Punjab derasar',
    state: 'Punjab',
    city: 'Faridkot',
    deity: 'Rishabhanatha',
    tradition: 'jain',
  ),
  _t(
    name: 'Harmandir',
    state: 'Punjab',
    city: 'Amritsar',
    deity: 'Guru Granth Sahib',
    tradition: 'sikh',
  ),
  _t(name: 'Kerala shiva', state: 'Kerala', city: 'Vaikom', deity: 'Shiva'),
];

String? _cityDistrict(Temple temple) => temple.city;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('Punjab + Shiva Hindu count includes only the Shiva listing', () {
    final census = directoryOptionCensus(
      _listed,
      state: 'Punjab',
      deity: 'Shiva',
    );
    expect(census.traditionCount('hindu'), 1);
    expect(census.traditionCount('jain'), 1);
    expect(census.traditionCount('sikh'), 1);
  });

  test('each tradition option count equals the list after applying it', () {
    const states = [null, 'Punjab', 'Rajasthan', 'Kerala'];
    const deities = [null, 'Shiva', 'Rishabhanatha', 'Durga'];
    const districts = [null, 'Amritsar', 'Mount Abu'];
    const queries = ['', 'shiva', 'abu'];
    for (final state in states) {
      for (final deity in deities) {
        for (final district in districts) {
          for (final query in queries) {
            final census = directoryOptionCensus(
              _listed,
              state: state,
              deity: deity,
              district: district,
              query: query,
              districtOf: _cityDistrict,
            );
            expect(
              census.anyTradition,
              directoryMatchingTemples(
                _listed,
                state: state,
                deity: deity,
                district: district,
                query: query,
                districtOf: _cityDistrict,
              ).length,
              reason: 'anyTradition $state $deity $district $query',
            );
            for (final key in directoryTraditionOrder) {
              final nextDeity =
                  directoryDeityFitsTradition(
                    _listed,
                    deity: deity,
                    tradition: key,
                  )
                  ? deity
                  : null;
              final applied = directoryMatchingTemples(
                _listed,
                state: state,
                deity: nextDeity,
                district: district,
                tradition: key,
                query: query,
                districtOf: _cityDistrict,
              );
              expect(
                census.traditionCount(key),
                applied.length,
                reason: 'option $key at $state $deity $district $query',
              );
            }
          }
        }
      }
    }
  });

  testWidgets('a selected tradition with 0 results stays visible', (t) async {
    await pumpFilterBar(
      t,
      temples: [
        _t(name: 'Vaikom', state: 'Kerala', city: 'Vaikom', deity: 'Shiva'),
      ],
      initialTradition: 'sikh',
      initialState: 'Kerala',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('filter-chip-tradition')),
        matching: find.text('Sikh'),
      ),
      findsOneWidget,
    );
    await openFilterChip(t, 'tradition');
    expect(
      find.byKey(const Key('filter-option-tradition-sikh')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-option-tradition-hindu')),
      findsOneWidget,
    );
  });

  testWidgets(
    'Hindu option is shown for documents that omit the tradition field',
    (t) async {
      await pumpFilterBar(
        t,
        temples: [
          _t(name: 'Vaikom', state: 'Kerala', city: 'Vaikom', deity: 'Shiva'),
        ],
      );
      await openFilterChip(t, 'tradition');
      expect(
        find.byKey(const Key('filter-option-tradition-hindu')),
        findsOneWidget,
      );
    },
  );
}
