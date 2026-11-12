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

  testWidgets('back_closes_sheet_not_page_test', (tester) async {
    final temples = [
      filterTemple(
        name: 'Vaikom Mahadeva Temple',
        state: 'Kerala',
        city: 'Kottayam',
        deity: 'Shiva',
      ),
    ];
    useFilterSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleBrowseList(temples: temples),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('All places'), findsNothing);
    expect(find.byType(TempleBrowseList), findsOneWidget);

    await openFilterChip(tester, 'state');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-sheet')), findsNothing);
    expect(find.byType(TempleBrowseList), findsOneWidget);
    expect(find.byKey(const Key('filter-chip-state')), findsOneWidget);
  });

  testWidgets('browse, drawer, and home each open their own sheet', (
    tester,
  ) async {
    useFilterSurface(tester);
    final temples = [
      filterTemple(
        name: 'Vaikom Mahadeva Temple',
        state: 'Kerala',
        city: 'Kottayam',
        deity: 'Shiva',
      ),
    ];
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
    await tester.tap(find.byKey(const Key('home-browse-temples')));
    await tester.pumpAndSettle();
    await openFilterChip(tester, 'deity');
    expect(find.byKey(const Key('filter-section-deity')), findsOneWidget);
    expect(find.byKey(const Key('filter-option-state-Kerala')), findsNothing);
    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    final stateChip = find.descendant(
      of: find.byType(Drawer),
      matching: find.byKey(const Key('filter-chip-state')),
    );
    await tester.ensureVisible(stateChip);
    await tester.tap(stateChip);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-section-state')), findsOneWidget);
    expect(find.byKey(const Key('filter-section-deity')), findsNothing);
  });
}
