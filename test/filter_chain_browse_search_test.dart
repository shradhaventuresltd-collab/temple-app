import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/widgets/app_drawer.dart';

import 'filter_sheet_support.dart';
import 'helpers/fake_admin_auth.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

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

  Future<void> chain(WidgetTester tester) async {
    await openFilterChip(tester, 'state');
    await chooseAndApply(tester, const Key('filter-option-state-Kerala'));
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);

    await openFilterChip(tester, 'state');
    expect(find.byKey(const Key('filter-option-state-Kerala')), findsOneWidget);
    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);

    await openFilterChip(tester, 'district');
    if (find.byKey(const Key('filter-choose-state-first')).evaluate().isNotEmpty) {
      await chooseAndApply(tester, const Key('filter-option-state-Kerala'));
    }
    if (find.byKey(const Key('filter-district-loading')).evaluate().isEmpty) {
      final district = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('filter-option-district-') &&
            key.value != 'filter-option-district-any';
      });
      final target = district.evaluate().isEmpty
          ? find.byKey(const Key('filter-option-district-any'))
          : district.first;
      expect(target, findsWidgets);
      await tester.tap(target);
      await tester.pump();
      await applyFilterSheet(tester);
    } else {
      await tester.tap(find.byKey(const Key('filter-sheet-close')));
      await tester.pumpAndSettle();
    }
    await openFilterChip(tester, 'deity');
    await chooseAndApply(tester, const Key('filter-option-deity-Shiva'));
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-clear')), findsNothing);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
  }

  testWidgets('filter bar State, District, Deity, then Clear all', (tester) async {
    String? districtOf(temple) => temple.city as String;
    await pumpFilterBar(tester, temples: temples, districtOf: districtOf);
    await openFilterChip(tester, 'state');
    await chooseAndApply(tester, const Key('filter-option-state-Kerala'));
    await openFilterChip(tester, 'state');
    expect(find.byKey(const Key('filter-option-state-Kerala')), findsOneWidget);
    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();
    await openFilterChip(tester, 'district');
    await chooseAndApply(tester, const Key('filter-option-district-Kottayam'));
    await openFilterChip(tester, 'deity');
    await chooseAndApply(tester, const Key('filter-option-deity-Shiva'));
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);
    await tester.tap(find.byKey(const Key('filter-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
  });

  testWidgets('browse State, District, Deity, then Clear all', (tester) async {
    useFilterSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleBrowseList(temples: temples),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await chain(tester);
  });

  testWidgets('drawer Search State, District, Deity, then Clear all', (
    tester,
  ) async {
    useFilterSurface(tester);
    TempleService.readsBlocked = () => true;
    TempleService.published = temples;
    addTearDown(TempleService.resetSessionForTest);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          adminAuth: FakeAdminAuth(),
          adminToolsEnabled: false,
          templesLoader: () async => temples,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('temple-drawer-search-field')),
      'Temple',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byType(TempleBrowseList), findsOneWidget);
    await chain(tester);
  });
}
