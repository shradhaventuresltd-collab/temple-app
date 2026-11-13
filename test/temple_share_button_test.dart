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

  group('share button look and placement (SHARE-SPEC.md)', () {
    testWidgets('sits under Get Directions in How to Reach, not the header', (
      tester,
    ) async {
      await pumpDetail(tester);
      await tester.ensureVisible(share);
      await tester.pumpAndSettle();
      final directions = tester.getRect(
        find.byKey(const Key('get-directions-button')),
      );
      final button = tester.getRect(share);
      expect(button.top - directions.bottom, closeTo(10, 0.5));
      expect(button.width, closeTo(directions.width, 0.5));
      expect(button.height, greaterThanOrEqualTo(TempleShareButton.minHeight));
      expect(find.byIcon(Icons.share), findsNothing, reason: 'old header icon');
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(
        tester.getRect(find.text('About')).top,
        greaterThan(button.bottom),
      );
    });

    testWidgets('outlined, #E65100, 1.5 border, radius 12, Poppins 15 w600', (
      tester,
    ) async {
      await pumpDetail(tester);
      final button = tester.widget<OutlinedButton>(share);
      final style = button.style!;
      final side = style.side!.resolve({})!;
      expect(side.color, const Color(0xFFE65100));
      expect(side.width, 1.5);
      final shape = style.shape!.resolve({})! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
      expect(style.backgroundColor!.resolve({}), Colors.white);
      expect(
        style.overlayColor!.resolve({WidgetState.pressed}),
        const Color(0xFFE65100).withValues(alpha: 0.08),
      );
      final label = tester.widget<Text>(
        find.descendant(of: share, matching: find.text('Share')),
      );
      expect(label.style!.fontSize, 15);
      expect(label.style!.fontWeight, FontWeight.w600);
      expect(label.style!.color, const Color(0xFFE65100));
    });

    testWidgets('semantics: label, hint, button', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDetail(tester);
      await tester.ensureVisible(share);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Share').first),
        matchesSemantics(
          label: 'Share',
          hint: ShareStrings.templeDetailShareTooltip,
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('dark theme uses the dark tokens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(body: TempleShareButton(onPressed: () {})),
        ),
      );
      final style = tester.widget<OutlinedButton>(share).style!;
      expect(style.side!.resolve({})!.color, TempleShareButton.darkAccent);
      expect(style.backgroundColor!.resolve({}), TempleShareButton.darkFill);
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
