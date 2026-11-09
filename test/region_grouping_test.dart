import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/utils/india_regions.dart';

import 'filter_sheet_support.dart';

void main() {
  test('region_grouping_test every catalogued state maps once', () {
    final seen = <String>{};
    for (final entry in kIndiaStateRegions) {
      expect(seen.add(entry.name), isTrue, reason: '${entry.name} is listed twice');
      expect(indiaRegionOf(entry.name), isNotNull, reason: entry.name);
    }
    expect(indiaRegionOf('Uttar Pradesh'), IndiaRegion.north);
    expect(indiaRegionOf('Uttarakhand'), IndiaRegion.north);
    expect(indiaRegionOf('Rajasthan'), IndiaRegion.west);
    expect(indiaRegionOf('Sikkim'), IndiaRegion.east);
    expect(indiaRegionOf('Arunachal Pradesh'), IndiaRegion.east);
    expect(indiaRegionOf('Madhya Pradesh'), IndiaRegion.central);
    expect(indiaRegionOf('Andaman & Nicobar Islands'), IndiaRegion.south);
    expect(indiaRegionOf('Andaman and Nicobar Islands'), IndiaRegion.south);
    expect(indiaStateSectionId('Sikkim'), 'northeast');
    expect(indiaRegionOf('Atlantis'), isNull);
  });

  test('region_grouping_test every bundled directory state maps once', () {
    final states = sampleTemples.map((temple) => temple.state.trim()).toSet();
    expect(states, isNotEmpty);
    for (final state in states) {
      final region = indiaRegionOf(state);
      expect(region, isNotNull, reason: state);
      expect(
        IndiaRegion.values.where((item) => item == region),
        hasLength(1),
        reason: state,
      );
    }
  });

  test('unmapped labels are kept under Other', () {
    final sections = groupStatesByRegion(['Kerala', 'Atlantis', 'Kerala']);
    expect(sections.map((section) => section.id), ['south', 'other']);
    expect(
      sections.singleWhere((section) => section.id == 'other').states,
      ['Atlantis'],
    );
  });

  testWidgets('region_grouping_test hides a zero-count state', (tester) async {
    final temples = [
      filterTemple(
        name: 'Vaikom',
        state: 'Kerala',
        city: 'Kottayam',
        deity: 'Shiva',
      ),
      filterTemple(
        name: 'Meenakshi',
        state: 'Tamil Nadu',
        city: 'Madurai',
        deity: 'Devi',
      ),
      filterTemple(
        name: 'Lost city',
        state: 'Atlantis',
        city: 'Nowhere',
        deity: 'Shiva',
      ),
    ];
    await pumpFilterBar(
      tester,
      temples: temples,
      initialDeity: 'Shiva',
    );
    await openFilterChip(tester, 'state');
    expect(find.text('Kerala'), findsWidgets);
    expect(
      find.byKey(const Key('filter-option-state-Tamil Nadu')),
      findsNothing,
    );
    expect(find.text('OTHER'), findsOneWidget);
    expect(find.text('Atlantis'), findsWidgets);
  });
}
