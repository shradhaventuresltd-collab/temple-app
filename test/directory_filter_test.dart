import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/widgets/app_drawer.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Temple temple({
    required String name,
    required String state,
    required String city,
    required String deity,
  }) {
    return Temple(
      name: name,
      state: state,
      city: city,
      deity: deity,
      imageUrl: '',
      description: '',
      story: '',
      location: '$city, $state',
      timings: '',
      specialities: const [],
      latitude: 0,
      longitude: 0,
    );
  }

  final temples = [
    temple(
      name: 'Meenakshi Amman Temple',
      state: 'Tamil Nadu',
      city: 'Madurai',
      deity: 'Devi',
    ),
    temple(
      name: 'Vaikom Mahadeva Temple',
      state: 'Kerala',
      city: 'Kottayam',
      deity: 'Shiva',
    ),
    temple(
      name: 'Dilwara Temples',
      state: 'Rajasthan',
      city: 'Mount Abu',
      deity: 'Jain Tirthankaras',
    ),
  ];

  Future<void> pumpList(
    WidgetTester tester, {
    String? initialState,
    String? initialDeity,
    String initialQuery = '',
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleBrowseList(
            temples: temples,
            initialQuery: initialQuery,
            initialState: initialState,
            initialDeity: initialDeity,
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('filter-chip-state')));
    await tester.pumpAndSettle();
  }

  test('supported filters stay state and deity, with tradition labels', () {
    expect(directoryFilterStates, contains('Tamil Nadu'));
    expect(directoryFilterDeities, contains('Shiva'));
    expect(directoryFilterDeities, contains('Jain Tirthankaras'));
    expect(directoryFilterDeities, contains('Buddha'));
    expect(directoryFilterDeities, contains('Muthappan'));
    expect(listedDeityTraditionLabel('Jain Tirthankaras'), 'Jain');
    expect(listedDeityTraditionLabel('Buddha'), 'Buddhist');
    expect(listedDeityTraditionLabel('Shiva'), isNull);
    expect(directoryDeityChipLabel('Buddha'), 'Buddha · Buddhist');
    expect(
      directoryDeityFilterNote(),
      'Jain and Buddhist labels are the listed tradition, not Hindu darshan filters.',
    );
    expect(
      directoryFilterCount(temples, state: 'Kerala', deity: 'Shiva'),
      1,
    );
    expect(directoryBrowseTitle(state: 'Kerala', deity: 'Shiva'), 'Shiva · Kerala');
  });

  testWidgets('state and deity chips filter the loaded list together', (
    tester,
  ) async {
    await pumpList(tester);
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Dilwara Temples'), findsOneWidget);

    await openSheet(tester);
    expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.byKey(const Key('filter-deity-note')), findsOneWidget);
    expect(find.textContaining('Hindu darshan'), findsOneWidget);
    expect(find.textContaining('Buddha · Buddhist'), findsOneWidget);
    expect(find.text('District'), findsNothing);
    expect(find.text('Festival'), findsNothing);
    expect(find.text('ASI'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-option-state-Kerala')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('filter-option-deity-Shiva')));
    await tester.pump();
    expect(find.text('Show 1 temple'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-sheet-apply')));
    await tester.pumpAndSettle();

    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);
    expect(find.text('Dilwara Temples'), findsNothing);
    expect(find.text('1 temple'), findsOneWidget);
    expect(find.text('Kottayam, Kerala'), findsOneWidget);
  });

  testWidgets('closing the sheet keeps the previous list', (tester) async {
    await pumpList(tester);
    await openSheet(tester);
    await tester.tap(find.byKey(const Key('filter-option-state-Kerala')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();

    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.byKey(const Key('filter-clear')), findsNothing);
  });

  testWidgets('clear and reset restore the loaded directory', (tester) async {
    await pumpList(tester, initialState: 'Kerala', initialDeity: 'Shiva');
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-chip-state-clear')));
    await tester.pump();
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-clear')));
    await tester.pump();
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Dilwara Temples'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
  });

  testWidgets('sheet clear resets the draft before apply', (tester) async {
    await pumpList(tester, initialState: 'Tamil Nadu');
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);

    await openSheet(tester);
    await tester.tap(find.byKey(const Key('filter-sheet-clear')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('filter-sheet-apply')));
    await tester.pumpAndSettle();

    expect(find.text('Show 3 temples'), findsNothing);
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Dilwara Temples'), findsOneWidget);
  });

  testWidgets('empty filter results are honest and clear restores the list', (
    tester,
  ) async {
    await pumpList(tester, initialState: 'Tamil Nadu', initialDeity: 'Shiva');

    expect(find.text('No temples match these filters.'), findsOneWidget);
    expect(
      find.text('Nothing in the loaded directory fits this state and deity.'),
      findsOneWidget,
    );
    expect(find.text('Meenakshi Amman Temple'), findsNothing);
    expect(find.textContaining('Seed'), findsNothing);
    expect(find.textContaining('Admin'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-empty-clear')));
    await tester.pump();

    expect(find.text('No temples match these filters.'), findsNothing);
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
  });

  testWidgets('filters combine with the existing search query', (tester) async {
    await pumpList(tester, initialState: 'Kerala', initialQuery: 'vaikom');
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('temple-list-search-field')),
      'madurai',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('No temples match these filters and "madurai".'),
      findsOneWidget,
    );
    expect(find.textContaining('Seed'), findsNothing);
    expect(find.textContaining('Admin'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-empty-clear')));
    await tester.pump();

    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);
  });

  testWidgets('a Jain listing keeps its tradition chip when filtered', (
    tester,
  ) async {
    await pumpList(tester, initialState: 'Rajasthan', initialDeity: 'Jain Tirthankaras');

    expect(find.text('Dilwara Temples'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);
    expect(find.text('Jain'), findsOneWidget);
    expect(find.textContaining('Jain Tirthankaras · Jain'), findsOneWidget);
    expect(find.textContaining('darshan'), findsNothing);
  });
}
