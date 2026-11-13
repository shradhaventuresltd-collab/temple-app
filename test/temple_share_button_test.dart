import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/share_strings.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/services/review_prompt.dart';
import 'package:temple_app/services/temple_share.dart';
import 'package:temple_app/widgets/temple_share_button.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'helpers/fake_review.dart';

const _play =
    'https://play.google.com/store/apps/details?id=com.shradhaventures.temple';

Temple _temple({String city = 'Madurai', String state = 'Tamil Nadu'}) {
  return Temple(
    id: 'meenakshi',
    name: 'Meenakshi Amman Temple',
    state: state,
    city: city,
    deity: 'Devi',
    imageUrl: '',
    description: 'A place listed in the directory.',
    story: 'Notes are still being checked.',
    location: 'Temple Street',
    timings: '6:00 AM–8:00 PM daily.',
    specialities: const ['Stone gateway'],
    latitude: 9.9195,
    longitude: 78.1193,
  );
}

class _OpeningLauncher extends UrlLauncherPlatform {
  _OpeningLauncher({this.opens = true});

  final bool opens;
  int launches = 0;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => opens;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launches += 1;
    return opens;
  }
}

void main() {
  late UrlLauncherPlatform originalLauncher;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    originalLauncher = UrlLauncherPlatform.instance;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalLauncher;
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    Temple? temple,
    TempleSharer? sharer,
    ReviewPrompter? reviewPrompter,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(
            temple: temple ?? _temple(),
            sharer: sharer ?? FakeTempleSharer(),
            reviewPrompter: reviewPrompter ?? ReviewPrompter.disabled(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final share = find.byKey(const Key('detail-share-button'));

  group('share button', () {
    testWidgets('is on the photo header with the share icon and a tooltip', (
      tester,
    ) async {
      await pumpDetail(tester);
      expect(share, findsOneWidget);
      final button = tester.widget<IconButton>(share);
      expect(button.tooltip, ShareStrings.templeDetailShareTooltip);
      expect(
        find.descendant(of: share, matching: find.byIcon(Icons.share)),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Share'), findsOneWidget);
      await tester.longPress(share);
      await tester.pumpAndSettle();
      expect(find.text('Share this place'), findsOneWidget);
    });

    testWidgets('tap shares name, town and state, and the Play link', (
      tester,
    ) async {
      final sharer = FakeTempleSharer();
      await pumpDetail(tester, sharer: sharer);
      await tester.tap(share);
      await tester.pump();
      expect(sharer.texts, [
        'Meenakshi Amman Temple\n'
            'Madurai, Tamil Nadu\n'
            '\n'
            "Explore India's sacred places on Temple Directory India:\n"
            '$_play',
      ]);
      expect(sharer.subjects, ['Meenakshi Amman Temple']);
      expect(sharer.texts.single, isNot(contains('temple-app://')));
    });

    testWidgets('missing town shares the state with no dangling comma', (
      tester,
    ) async {
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        temple: _temple(city: ''),
      );
      await tester.tap(share);
      await tester.pump();
      expect(sharer.texts.single.split('\n')[1], 'Tamil Nadu');
    });

    testWidgets('double tap while the sheet is opening shares once', (
      tester,
    ) async {
      final sheet = Completer<void>();
      final sharer = FakeTempleSharer(hold: sheet.future);
      await pumpDetail(tester, sharer: sharer);
      await tester.tap(share);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(share);
      await tester.pump();
      expect(sharer.texts, hasLength(1));

      // Sheet dismissed: the next tap opens it again.
      sheet.complete();
      await tester.pump();
      sharer.hold = null;
      await tester.tap(share);
      await tester.pump();
      expect(sharer.texts, hasLength(2));
    });

    testWidgets('a share failure is silent and the button still works', (
      tester,
    ) async {
      final sharer = FakeTempleSharer(error: Exception('no share target'));
      await pumpDetail(tester, sharer: sharer);
      await tester.tap(share);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
      sharer.error = null;
      await tester.tap(share);
      await tester.pump();
      expect(sharer.texts, hasLength(2));
    });

    testWidgets('sits left of Home at the same size', (tester) async {
      await pumpDetail(tester);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      final shareBox = tester.getRect(share);
      final homeBox = tester.getRect(find.byIcon(Icons.home_rounded));
      expect(shareBox.right, lessThanOrEqualTo(homeBox.left));
      expect(shareBox.height, TempleShareButton.size);
    });
  });

  group('review after Get Directions', () {
    Future<void> tapDirections(WidgetTester tester) async {
      final button = find.byKey(const Key('get-directions-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> leaveAndReturn(WidgetTester tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
    }

    late FakeReviewClient client;
    late MemoryReviewPromptStore store;
    late DateTime now;

    setUp(() {
      client = FakeReviewClient();
      store = MemoryReviewPromptStore(sessionCount: 2);
      now = DateTime.utc(2026, 11, 13);
    });

    ReviewPrompter prompter() =>
        ReviewPrompter(client: client, store: store, now: () => now);

    testWidgets('asks after Maps opened and the user came back', (
      tester,
    ) async {
      UrlLauncherPlatform.instance = _OpeningLauncher();
      await pumpDetail(tester, reviewPrompter: prompter());
      await tapDirections(tester);
      expect(client.requests, 0, reason: 'not while Maps is in front');
      await leaveAndReturn(tester);
      expect(client.requests, 1);
    });

    testWidgets('no ask when Maps could not open', (tester) async {
      UrlLauncherPlatform.instance = _OpeningLauncher(opens: false);
      await pumpDetail(tester, reviewPrompter: prompter());
      await tapDirections(tester);
      await leaveAndReturn(tester);
      expect(client.requests, 0);
    });

    testWidgets('no ask in the first session', (tester) async {
      store.sessionCount = 1;
      UrlLauncherPlatform.instance = _OpeningLauncher();
      await pumpDetail(tester, reviewPrompter: prompter());
      await tapDirections(tester);
      await leaveAndReturn(tester);
      expect(client.requests, 0);
    });

    testWidgets('repeated directions within the cooldown ask once', (
      tester,
    ) async {
      UrlLauncherPlatform.instance = _OpeningLauncher();
      await pumpDetail(tester, reviewPrompter: prompter());
      for (var i = 0; i < 4; i++) {
        await tapDirections(tester);
        await leaveAndReturn(tester);
        now = now.add(const Duration(days: 3));
      }
      expect(client.requests, 1);
    });

    testWidgets('a throwing review client never reaches the UI', (
      tester,
    ) async {
      client.availableError = Exception('Play services missing');
      UrlLauncherPlatform.instance = _OpeningLauncher();
      await pumpDetail(tester, reviewPrompter: prompter());
      await tapDirections(tester);
      await leaveAndReturn(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(client.requests, 0);
    });
  });
}
