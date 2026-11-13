// KAN-186 review: "Try again" on the drawer list (PR #127).
import 'dart:async';

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

final _retry = find.byKey(const Key('browse-load-failed-retry'));

Future<void> _pumpFailed(
  WidgetTester tester, {
  required Future<List<Temple>> Function() loader,
  bool viaFuture = false,
}) async {
  final open = Completer<List<Temple>>();
  await tester.pumpWidget(
    MaterialApp(
      home: TempleListScreen(
        temples: const [],
        title: 'All places',
        // ~845: opened with loadFailed. ~881: templesFuture errored.
        loadFailed: !viaFuture,
        templesFuture: viaFuture ? open.future : null,
        retryLoader: loader,
      ),
    ),
  );
  await tester.pump();
  if (viaFuture) open.completeError(StateError('offline'));
  await tester.pump();
  await tester.pump();
  expect(find.text('Could not load places'), findsOneWidget);
  expect(find.byType(DirectoryFilterBar), findsNothing);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(TempleService.resetSessionForTest);
  tearDown(TempleService.resetSessionForTest);

  for (final viaFuture in [false, true]) {
    final where = viaFuture ? 'templesFuture error' : 'loadFailed open';
    testWidgets('Try again brings back list and chips ($where)', (
      tester,
    ) async {
      var loads = 0;
      await _pumpFailed(
        tester,
        viaFuture: viaFuture,
        loader: () async {
          loads++;
          return [_temple('Vaikom Mahadeva Temple')];
        },
      );
      await tester.tap(_retry);
      await tester.pump();
      await tester.pump();
      expect(loads, 1);
      expect(find.text('Could not load places'), findsNothing);
      expect(find.text('Vaikom Mahadeva Temple'), findsWidgets);
      expect(find.byType(DirectoryFilterBar), findsOneWidget);
    });
  }

  testWidgets('double tap on Try again starts exactly one load', (
    tester,
  ) async {
    var loads = 0;
    final pending = Completer<List<Temple>>();
    await _pumpFailed(
      tester,
      loader: () {
        loads++;
        return pending.future;
      },
    );
    await tester.tap(_retry);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_retry);
    await tester.pump();
    expect(loads, 1);
    pending.complete([_temple('Vaikom Mahadeva Temple')]);
    await tester.pump();
    await tester.pump();
    expect(find.byType(DirectoryFilterBar), findsOneWidget);
  });

  testWidgets('failed retry shows feedback and allows another try', (
    tester,
  ) async {
    var loads = 0;
    await _pumpFailed(
      tester,
      loader: () async {
        loads++;
        throw StateError('still offline');
      },
    );
    await tester.tap(_retry);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('temple-list-retry-failed')), findsOneWidget);
    expect(find.text('Could not load places'), findsOneWidget);
    await tester.tap(_retry);
    await tester.pump();
    expect(loads, 2);
  });

  testWidgets('Try again has semantics identifier temple-list-try-again', (
    tester,
  ) async {
    await _pumpFailed(tester, loader: () async => const []);
    final ids = find.byWidgetPredicate(
      (w) =>
          w is Semantics && w.properties.identifier == 'temple-list-try-again',
    );
    expect(ids, findsOneWidget);
    expect(find.descendant(of: ids, matching: _retry), findsOneWidget);
  });
}
