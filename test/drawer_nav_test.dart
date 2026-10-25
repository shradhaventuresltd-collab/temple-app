import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/widgets/app_drawer.dart';

import 'helpers/fake_admin_auth.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _RouteLog routes;

  setUp(() {
    routes = _RouteLog();
    TempleService.readsBlocked = () => true;
    TempleService.published = [_sampleTemple()];
  });

  tearDown(TempleService.resetSessionForTest);

  testWidgets(
    'P2 list drawer All Temples closes the drawer and shows the list',
    (tester) async {
      await _pumpHome(tester, routes);
      await tester.tap(find.byKey(const Key('home-browse-temples')));
      await tester.pumpAndSettle();
      expect(find.byType(TempleListScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('All Temples'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      expect(find.byType(TempleListScreen), findsOneWidget);
      expect(find.byKey(const Key('temple-list-title')), findsOneWidget);
      expect(find.text('Meenakshi Amman Temple').hitTestable(), findsOneWidget);
      expect(routes.depth, 2);
    },
  );

  testWidgets('P2 double tap All Temples does not stack lists', (tester) async {
    await _pumpHome(tester, routes);
    await tester.tap(find.byKey(const Key('home-browse-temples')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    final allTemples = find.descendant(
      of: find.byType(Drawer),
      matching: find.text('All Temples'),
    );
    await _doubleTap(tester, allTemples);

    expect(find.byType(Drawer), findsNothing);
    expect(find.byType(TempleListScreen), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple').hitTestable(), findsOneWidget);
    expect(routes.depth, 2, reason: routes.events.join(' | '));
  });

  testWidgets('P3 double tap Home closes the drawer and leaves one route', (
    tester,
  ) async {
    await _pumpHome(tester, routes);
    expect(routes.depth, 1);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    final homeTile = find.descendant(
      of: find.byType(Drawer),
      matching: find.text('Home'),
    );
    await _doubleTap(tester, homeTile);

    expect(find.byType(Drawer), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.byKey(const Key('home-browse-temples')).hitTestable(),
      findsOneWidget,
    );
    expect(routes.depth, 1, reason: routes.events.join(' | '));
  });

  testWidgets('Home on the home screen does not hold the navigation guard', (
    tester,
  ) async {
    await _pumpHome(tester, routes);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Home')),
    );
    // The close rebuilds once while the same-turn guard is set. The next
    // frame drops it. A 400ms hold would still be up here.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final allTemples = find.descendant(
      of: find.byType(Drawer),
      matching: find.text('All Temples'),
    );
    final tile = find.ancestor(of: allTemples, matching: find.byType(ListTile));
    expect(tester.widget<ListTile>(tile).onTap, isNotNull);
  });

  testWidgets(
    'All Temples on the open list does not hold the navigation guard',
    (tester) async {
      await _pumpHome(tester, routes);
      await tester.tap(find.byKey(const Key('home-browse-temples')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('All Temples'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final home = find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Home'),
      );
      final tile = find.ancestor(of: home, matching: find.byType(ListTile));
      expect(tester.widget<ListTile>(tile).onTap, isNotNull);
    },
  );

  testWidgets(
    'a second Home tap during the close does not leave the drawer open',
    (tester) async {
      await _pumpHome(tester, routes);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      final homeTile = find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Home'),
      );
      await _tapTwiceWithDelay(tester, homeTile);

      expect(find.byType(Drawer), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.byKey(const Key('home-browse-temples')).hitTestable(),
        findsOneWidget,
      );
      expect(routes.depth, 1, reason: routes.events.join(' | '));
    },
  );

  testWidgets('P3 double tap Home from a list returns to one home route', (
    tester,
  ) async {
    await _pumpHome(tester, routes);
    await tester.tap(find.byKey(const Key('home-browse-temples')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    final homeTile = find.descendant(
      of: find.byType(Drawer),
      matching: find.text('Home'),
    );
    await _doubleTap(tester, homeTile);

    expect(find.byType(Drawer), findsNothing);
    expect(find.byType(TempleListScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(routes.depth, 1, reason: routes.events.join(' | '));
  });
}

class _RouteLog extends NavigatorObserver {
  final List<String> events = [];
  final List<Route<dynamic>> stack = [];

  int get depth => stack.length;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.add(route);
    events.add('push ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
    events.add('pop ${route.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
    events.add('remove ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) stack.remove(oldRoute);
    if (newRoute != null) stack.add(newRoute);
    events.add('replace ${newRoute?.settings.name}');
  }
}

Temple _sampleTemple() {
  return const Temple(
    name: 'Meenakshi Amman Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Devi',
    imageUrl: '',
    description: 'A historic temple.',
    story: 'Story',
    location: 'Madurai, Tamil Nadu',
    timings: '',
    specialities: [],
  );
}

/// Two real contacts, 80ms apart, the second moving past the touch slop.
///
/// A device double-tap is not two [onTap] calls in one turn, and it is not
/// a zero-delta pointer. The second finger arrives while the drawer is
/// still closing and moves far enough for the drawer's drag recognizer to
/// accept. That used to stop the fling and open the drawer again.
Future<void> _tapTwiceWithDelay(WidgetTester tester, Finder finder) async {
  final first = await tester.startGesture(tester.getCenter(finder));
  await first.up();
  await tester.pump(const Duration(milliseconds: 80));
  // The tile has slid. A second contact lands on the tile where it is now
  // and moves past the touch slop, the way a finger does on a device.
  final second = await tester.startGesture(tester.getCenter(finder));
  await second.moveBy(const Offset(24, 4));
  await second.up();
  await tester.pumpAndSettle();
}

/// Delivers two taps before the next frame.
///
/// A second pointer after the drawer has started closing no longer hits the
/// tile: the first pop already removed the drawer's local history, and the
/// tile's hit target has moved. Calling [onTap] twice is the re-entrant case
/// that used to pop the page underneath.
Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  final tile = find.ancestor(of: finder, matching: find.byType(ListTile));
  final onTap = tester.widget<ListTile>(tile).onTap;
  expect(onTap, isNotNull);
  onTap!();
  onTap();
  await tester.pumpAndSettle();
}

Future<void> _pumpHome(WidgetTester tester, _RouteLog routes) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      navigatorObservers: [routes],
      home: HomeScreen(
        adminAuth: FakeAdminAuth(),
        adminToolsEnabled: false,
        templesLoader: () async => [_sampleTemple()],
      ),
    ),
  );
  await tester.pumpAndSettle();
}
