import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/widgets/app_drawer.dart';
import 'package:temple_app/widgets/directory_filter_bar.dart';

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
    final withGoa = [
      ...temples,
      temple(name: 'Goan Shrine', state: 'Goa', city: 'Ponda', deity: 'Buddha'),
    ];
    expect(directoryStatesFrom(temples), ['Kerala', 'Rajasthan', 'Tamil Nadu']);
    expect(directoryStatesFrom(withGoa), contains('Goa'));
    expect(directoryStatesFrom(temples), isNot(contains('Himachal Pradesh')));
    expect(directoryDeitiesFrom(temples), [
      'Devi',
      'Jain Tirthankaras',
      'Shiva',
    ]);
    expect(directoryDeitiesFrom(withGoa), contains('Buddha'));
    expect(listedDeityTraditionLabel('Jain Tirthankaras'), 'Jain');
    expect(listedDeityTraditionLabel('Buddha'), 'Buddhist');
    expect(listedDeityTraditionLabel('Shiva'), isNull);
    expect(directoryDeityChipLabel('Buddha'), 'Buddha · Buddhist');
    expect(
      directoryDeityFilterNote(directoryDeitiesFrom(temples)),
      'Jain labels are the listed tradition, not Hindu darshan filters.',
    );
    expect(
      directoryDeityFilterNote(directoryDeitiesFrom(withGoa)),
      'Jain and Buddhist labels are the listed tradition, not Hindu darshan filters.',
    );
    expect(directoryFilterCount(temples, state: 'Kerala', deity: 'Shiva'), 1);
    expect(
      directoryBrowseTitle(state: 'Kerala', deity: 'Shiva'),
      'Shiva · Kerala',
    );
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
    expect(
      find.textContaining('Jain Tirthankaras · Jain', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Buddha'), findsNothing);
    expect(find.text('Goa'), findsNothing);
    expect(find.text('Himachal Pradesh'), findsNothing);
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
    await pumpList(
      tester,
      initialState: 'Rajasthan',
      initialDeity: 'Jain Tirthankaras',
    );

    expect(find.text('Dilwara Temples'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);
    expect(find.text('Jain'), findsOneWidget);
    expect(find.textContaining('Jain Tirthankaras · Jain'), findsOneWidget);
    expect(find.textContaining('darshan'), findsNothing);
  });

  testWidgets('deity chip opens the deity list and state chip opens states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final many = [
      for (var i = 0; i < 40; i++)
        temple(
          name: 'Temple $i',
          state: 'State ${i.toString().padLeft(2, '0')}',
          city: 'City $i',
          deity: 'Deity ${i.toString().padLeft(2, '0')}',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectoryFilterBar(
            temples: many,
            selectedState: null,
            selectedDeity: null,
            onChanged: (_, _, _) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('filter-chip-deity')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('filter-section-deity')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-option-deity-any')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-option-deity-Deity 00')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-option-state-any')).hitTestable(),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filter-chip-state')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('filter-section-state')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-option-state-any')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-option-state-State 00')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-option-deity-any')).hitTestable(),
      findsNothing,
    );
  });

  testWidgets(
    'dismissing the sheet does not block the next state, deity, or district selection',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? state;
      String? deity;
      String? district;
      String? districtOf(Temple temple) => switch (temple.city) {
        'Madurai' => 'Madurai',
        'Kottayam' => 'Kottayam',
        'Mount Abu' => 'Sirohi',
        _ => null,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                final visible = directoryMatchingTemples(
                  temples,
                  state: state,
                  deity: deity,
                  district: district,
                  districtOf: districtOf,
                );
                return Column(
                  children: [
                    DirectoryFilterBar(
                      temples: temples,
                      selectedState: state,
                      selectedDeity: deity,
                      selectedDistrict: district,
                      districtOf: districtOf,
                      onChanged: (nextState, nextDeity, nextDistrict) {
                        setState(() {
                          state = nextState;
                          deity = nextDeity;
                          district = nextDistrict;
                        });
                      },
                    ),
                    for (final temple in visible) Text(temple.name),
                  ],
                );
              },
            ),
          ),
        ),
      );

      Future<void> openDismissReopen(
        Key chip,
        Future<void> Function() dismiss,
      ) async {
        await tester.tap(find.byKey(chip));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
        await dismiss();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('filter-sheet')), findsNothing);
        expect(find.byKey(chip), findsOneWidget);
        await tester.tap(find.byKey(chip));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
      }

      Future<void> applyOption(Key option) async {
        await tester.tap(find.byKey(option));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('filter-sheet-apply')));
        await tester.tap(find.byKey(const Key('filter-sheet-apply')));
        await tester.pumpAndSettle();
      }

      await openDismissReopen(
        const Key('filter-chip-deity'),
        () => tester.tap(find.byKey(const Key('filter-sheet-close'))),
      );
      await applyOption(const Key('filter-option-deity-Shiva'));
      expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
      expect(find.text('Meenakshi Amman Temple'), findsNothing);
      expect(find.text('Dilwara Temples'), findsNothing);
      expect(find.text('Shiva'), findsWidgets);

      await tester.tap(find.byKey(const Key('filter-clear')));
      await tester.pump();

      await openDismissReopen(const Key('filter-chip-state'), () async {
        await tester.binding.handlePopRoute();
      });
      await applyOption(const Key('filter-option-state-Kerala'));
      expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
      expect(find.text('Meenakshi Amman Temple'), findsNothing);
      expect(find.text('Kerala'), findsWidgets);

      await tester.tap(find.byKey(const Key('filter-clear')));
      await tester.pump();

      await openDismissReopen(const Key('filter-chip-district'), () async {
        await tester.drag(find.byType(ListView), const Offset(0, 400));
      });
      await applyOption(const Key('filter-option-district-Madurai'));
      expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
      expect(find.text('Vaikom Mahadeva Temple'), findsNothing);
      expect(find.text('Madurai'), findsWidgets);

      await tester.tap(find.byKey(const Key('filter-clear')));
      await tester.pump();

      await openDismissReopen(const Key('filter-chip-deity'), () async {
        await tester.drag(find.byType(ListView), const Offset(0, 400));
      });
      await applyOption(const Key('filter-option-deity-Devi'));
      expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
      expect(find.text('Vaikom Mahadeva Temple'), findsNothing);
      expect(find.text('Dilwara Temples'), findsNothing);

      await tester.tap(find.byKey(const Key('filter-clear')));
      await tester.pump();

      await openDismissReopen(const Key('filter-chip-state'), () async {
        await tester.drag(find.byType(ListView), const Offset(0, 400));
      });
      await applyOption(const Key('filter-option-state-Tamil Nadu'));
      expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
      expect(find.text('Vaikom Mahadeva Temple'), findsNothing);
      expect(find.text('Dilwara Temples'), findsNothing);
      expect(find.text('Tamil Nadu'), findsWidgets);
    },
  );

  testWidgets('scrolling options does not dismiss the sheet', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final many = [
      for (var i = 0; i < 40; i++)
        temple(
          name: 'Temple $i',
          state: 'State ${i.toString().padLeft(2, '0')}',
          city: 'City $i',
          deity: 'Deity ${i.toString().padLeft(2, '0')}',
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectoryFilterBar(
            temples: many,
            selectedState: null,
            selectedDeity: null,
            onChanged: (_, _, _) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('filter-chip-deity')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
    expect(
      find.byKey(const Key('filter-option-deity-Deity 20')).hitTestable(),
      findsOneWidget,
    );

    final optionList = find.descendant(
      of: find.byKey(const Key('filter-sheet')),
      matching: find.byType(ListView),
    );
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: optionList, matching: find.byType(Scrollable)),
    );
    // Each return drag stays under the 72px pull-to-dismiss threshold, including
    // the last one that reaches the top and overscrolls.
    for (var step = 0; step < 40 && scrollable.position.pixels > 0; step++) {
      await tester.drag(optionList, const Offset(0, 64));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
    }
    expect(scrollable.position.pixels, 0);
    expect(
      find.byKey(const Key('filter-option-deity-Deity 00')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets(
    'district sheet swipe down dismisses from the title and the list',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final many = [
        for (var i = 0; i < 80; i++)
          Temple(
            name: 'Temple $i',
            state: 'Tamil Nadu',
            city: 'District ${i.toString().padLeft(2, '0')} long name',
            deity: 'Shiva',
            imageUrl: '',
            description: '',
            story: '',
            location: 'District $i, Tamil Nadu',
            timings: '',
            specialities: const [],
            latitude: 9.9 + i / 1000,
            longitude: 78.1,
          ),
      ];
      String? districtOf(Temple temple) => temple.city;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectoryFilterBar(
              temples: many,
              selectedState: null,
              selectedDeity: null,
              districtOf: districtOf,
              onChanged: (_, _, _) {},
            ),
          ),
        ),
      );

      Future<void> openDistrict() async {
        await tester.tap(find.byKey(const Key('filter-chip-district')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
        expect(find.text('DISTRICT'), findsOneWidget);
      }

      final optionList = find.descendant(
        of: find.byKey(const Key('filter-sheet')),
        matching: find.byType(ListView),
      );

      await openDistrict();
      await tester.drag(find.text('Filters'), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-sheet')), findsNothing);

      await openDistrict();
      await tester.drag(optionList, const Offset(0, 64));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-sheet')), findsOneWidget);

      await tester.drag(optionList, const Offset(0, -320));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
      final scrolled = tester
          .state<ScrollableState>(
            find.descendant(of: optionList, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      expect(scrolled, greaterThan(200));
      await tester.drag(optionList, const Offset(0, 200));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-sheet')), findsOneWidget);

      await tester.drag(find.text('Filters'), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-sheet')), findsNothing);

      await openDistrict();
      await tester.drag(optionList, const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-sheet')), findsNothing);
      expect(find.byKey(const Key('filter-chip-district')), findsOneWidget);
    },
  );

  testWidgets(
    'selected deity chip stays on screen at 320dp and exposes its id',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        String? districtOf(Temple temple) => temple.city;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DirectoryFilterBar(
                temples: temples,
                selectedState: 'Tamil Nadu',
                selectedDeity: 'Shiva',
                selectedDistrict: 'Madurai',
                districtOf: districtOf,
                onChanged: (_, _, _) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final clear = find.byKey(const Key('filter-chip-deity-clear'));
        expect(clear.hitTestable(), findsOneWidget);
        expect(tester.getRect(clear).right, lessThanOrEqualTo(320));

        final deity = tester.getSemantics(
          find.byKey(const Key('filter-chip-deity')),
        );
        expect(deity.identifier, 'filter-chip-deity');
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('district chosen while the directory is loading is kept', (
    tester,
  ) async {
    final completer = Completer<List<Temple>>();
    await tester.pumpWidget(
      MaterialApp(
        home: TempleListScreen(
          temples: const [],
          title: 'All Temples',
          templesFuture: completer.future,
          districtFilter: 'Sirohi',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Sirohi'), findsNothing);

    completer.complete([
      temple(
        name: 'Dilwara Temples',
        state: 'Rajasthan',
        city: 'Mount Abu',
        deity: 'Jain Tirthankaras',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('filter-chip-district')), findsOneWidget);
    expect(find.text('Sirohi'), findsOneWidget);
    expect(find.text('All districts'), findsNothing);
  });
}
