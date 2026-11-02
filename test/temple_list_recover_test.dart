// Run 40658283240, flow 27: after a cold start offline, the drawer list
// showed "Could not load temples" with no way to retry, and it stayed there
// (no filter chips) even after the directory loaded once the network was
// back.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/widgets/app_drawer.dart';
import 'package:temple_app/widgets/directory_filter_bar.dart';

Temple _temple(String name) => Temple(
  name: name,
  state: 'Kerala',
  city: 'Kottayam',
  deity: 'Shiva',
  imageUrl: '',
  description: '',
  story: '',
  location: 'Kottayam, Kerala',
  timings: '',
  specialities: const [],
  latitude: 0,
  longitude: 0,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(TempleService.resetSessionForTest);
  tearDown(TempleService.resetSessionForTest);

  testWidgets('load-failed browse list offers Try again', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleBrowseList(
            temples: const [],
            loadFailed: true,
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.text('Could not load temples'), findsOneWidget);
    await tester.tap(find.byKey(const Key('browse-load-failed-retry')));
    expect(retries, 1);
  });

  testWidgets('load-failed browse list without a retry keeps old copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TempleBrowseList(temples: [], loadFailed: true)),
      ),
    );
    expect(find.byKey(const Key('browse-load-failed-retry')), findsNothing);
  });

  testWidgets('failed list recovers when the directory is published', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TempleListScreen(
          temples: [],
          title: 'All Temples',
          loadFailed: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Could not load temples'), findsOneWidget);
    expect(find.byKey(const Key('browse-load-failed-retry')), findsOneWidget);

    // Home's reconnect reload (or Retry) publishes the directory.
    TempleService.published = [_temple('Vaikom Mahadeva Temple')];
    TempleService.revision.value = TempleService.revision.value + 1;
    await tester.pump();

    expect(find.text('Could not load temples'), findsNothing);
    expect(find.text('Vaikom Mahadeva Temple'), findsWidgets);
    expect(find.byType(DirectoryFilterBar), findsOneWidget);
  });
}
