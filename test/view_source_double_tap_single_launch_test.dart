// KAN-197 AC3: double-tapping "View source" opens the browser once, and
// coming back from the browser leaves the page and its scroll as they were.
import 'dart:async';

import 'package:flutter/gestures.dart' show kDoubleTapMinTime;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/widgets/unverified_source_notice.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'helpers/dress_code_fixtures.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final key in [kDressLink, kTimingsLink]) {
    testWidgets('$key: double tap while pending launches once', (t) async {
      final gate = Completer<void>();
      final l = installLauncher(FakeLauncher(gate: gate));
      await pumpDetail(t, dressTemple(timingsUnverified: true));
      await t.ensureVisible(find.byKey(key));
      await t.tap(find.byKey(key));
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(find.byKey(key));
      await t.pump();
      gate.complete();
      await t.pumpAndSettle();
      expect(l.launches, 1);
      expect(l.mode, PreferredLaunchMode.externalApplication);
    });
  }

  testWidgets('fast double tap (kDoubleTapTimeout) still one launch', (
    t,
  ) async {
    final gate = Completer<void>();
    final l = installLauncher(FakeLauncher(gate: gate));
    await pumpDetail(t, dressTemple());
    await t.ensureVisible(find.byKey(kDressLink));
    await t.tap(find.byKey(kDressLink));
    await t.pump(kDoubleTapMinTime);
    await t.tap(find.byKey(kDressLink));
    await t.pump();
    gate.complete();
    await t.pumpAndSettle();
    expect(l.launches, 1);
    expect(l.urls.single, kDressSrc);
  });

  testWidgets('a tap after the launch returns launches again', (t) async {
    final l = installLauncher(FakeLauncher());
    await pumpDetail(t, dressTemple());
    await t.ensureVisible(find.byKey(kDressLink));
    await t.tap(find.byKey(kDressLink));
    await t.pumpAndSettle();
    await t.tap(find.byKey(kDressLink));
    await t.pumpAndSettle();
    expect(l.launches, 2);
  });

  testWidgets('return from browser keeps the page and scroll offset', (
    t,
  ) async {
    final gate = Completer<void>();
    installLauncher(FakeLauncher(gate: gate));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Text('list', key: Key('list'))),
      ),
    );
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              Scaffold(body: TempleDetailBody(temple: dressTemple())),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(kDressLink));
    await t.pumpAndSettle();
    final scrollable = t.state<ScrollableState>(find.byType(Scrollable).first);
    final before = scrollable.position.pixels;
    expect(before, greaterThan(0));
    final linkBefore = t.getTopLeft(find.byKey(kDressLink));

    await t.tap(find.byKey(kDressLink));
    await t.pump();
    // Browser in front, then back.
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 3));
    gate.complete();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pumpAndSettle();

    expect(find.byType(TempleDetailBody), findsOneWidget);
    expect(find.byKey(const Key('list')), findsNothing);
    expect(scrollable.position.pixels, before);
    expect(t.getTopLeft(find.byKey(kDressLink)), linkBefore);
    expect(find.text(UnverifiedSourceNotice.launchFailedText), findsNothing);
    expect(nav.canPop(), isTrue);
  });

  testWidgets('failed launch after a double tap: one snackbar', (t) async {
    final gate = Completer<void>();
    installLauncher(FakeLauncher(result: false, gate: gate));
    await pumpDetail(t, dressTemple());
    await t.ensureVisible(find.byKey(kDressLink));
    await t.tap(find.byKey(kDressLink));
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(find.byKey(kDressLink));
    gate.complete();
    await t.pump();
    await t.pump();
    expect(find.text(UnverifiedSourceNotice.launchFailedText), findsOneWidget);
  });

  testWidgets('launcher throwing: snackbar, no crash', (t) async {
    installLauncher(ThrowingLauncher());
    await pumpDetail(t, dressTemple());
    await t.ensureVisible(find.byKey(kDressLink));
    await t.tap(find.byKey(kDressLink));
    await t.pump();
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text(UnverifiedSourceNotice.launchFailedText), findsOneWidget);
  });

  testWidgets('double tap on the notice body or text does nothing', (t) async {
    final l = installLauncher(FakeLauncher());
    await pumpDetail(t, dressTemple());
    await t.ensureVisible(find.byKey(kDressChip));
    for (final f in [
      find.text(UnverifiedSourceNotice.title),
      find.byKey(kDressBody),
    ]) {
      await t.tap(f);
      await t.pump(const Duration(milliseconds: 40));
      await t.tap(f);
      await t.pumpAndSettle();
    }
    expect(l.launches, 0);
    expect(t.takeException(), isNull);
  });
}
