// Ux SHARE-SPEC.md named regression test, plus the spec's real-user
// sequences that a widget test can drive. Sequences 1, 2, 4 and 7 also run
// on the emulator (tool/emulator/flows/32_share_entry_points.sh).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/share_strings.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/screens/temples_near_me_screen.dart';
import 'package:temple_app/services/analytics_client.dart';
import 'package:temple_app/services/app_analytics.dart';
import 'package:temple_app/services/review_prompt.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/services/temple_share.dart';
import 'package:temple_app/widgets/app_drawer.dart' show TempleListScreen;
import 'package:temple_app/widgets/temple_browse_card.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'helpers/fake_admin_auth.dart';
import 'helpers/fake_review.dart';
import 'temples_near_me_screen_test.dart' show FakeCoarseLocation;

const _play =
    'https://play.google.com/store/apps/details?id=com.shradhaventures.temple';

Temple _temple({
  String id = 'kadri-manjunath',
  String name = 'Kadri Manjunath Temple',
  String city = 'Mangaluru',
  String state = 'Karnataka',
  String deity = 'Shiva',
  String? tradition,
  double? lat = 12.886,
  double? lng = 74.856,
}) {
  return Temple(
    id: id,
    name: name,
    state: state,
    city: city,
    deity: deity,
    imageUrl: '',
    description: 'A place listed in the directory.',
    story: 'Notes are still being checked.',
    location: 'Kadri, $city, $state',
    timings: '6:00 AM–8:00 PM daily.',
    specialities: const ['Stone gateway'],
    latitude: lat,
    longitude: lng,
    tradition: tradition,
  );
}

String _expected(Temple t) {
  final place = [t.city, t.state].where((p) => p.isNotEmpty).join(', ');
  return [
    t.name,
    if (place.isNotEmpty) place,
    'Found on Temple Directory India: $_play',
  ].join('\n');
}

class _Events implements AnalyticsClient {
  final events = <({String name, Map<String, Object>? parameters})>[];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    events.add((name: name, parameters: parameters));
  }

  @override
  Future<void> logScreenView({required String screenName}) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setConsent({
    required bool adPersonalizationSignalsConsentGranted,
    required bool adUserDataConsentGranted,
  }) async {}
}

class _UrlLauncher extends UrlLauncherPlatform {
  _UrlLauncher({this.canWhatsApp = true, this.launches = const {}});

  final bool canWhatsApp;

  /// Scheme -> launch result. Missing schemes return false.
  final Map<String, bool> launches;
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async =>
      url.startsWith('whatsapp:') ? canWhatsApp : true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return launches[Uri.parse(url).scheme] ?? false;
  }
}

void main() {
  late _Events analytics;
  late UrlLauncherPlatform originalLauncher;
  late TempleSharer originalSharer;
  late WhatsAppLauncher originalWhatsApp;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    analytics = _Events();
    AppAnalytics.resetForTest(
      AppAnalytics(client: analytics, collectionEnabled: true),
    );
    originalLauncher = UrlLauncherPlatform.instance;
    originalSharer = TempleSharer.instance;
    originalWhatsApp = WhatsAppLauncher.instance;
  });

  tearDown(() {
    AppAnalytics.resetForTest();
    UrlLauncherPlatform.instance = originalLauncher;
    TempleSharer.instance = originalSharer;
    WhatsAppLauncher.instance = originalWhatsApp;
  });

  final share = find.byKey(const Key('detail-share-button'));
  Finder label(String text) =>
      find.descendant(of: share, matching: find.text(text));

  Future<void> pumpDetail(
    WidgetTester tester, {
    Temple? temple,
    TempleSharer? sharer,
    WhatsAppLauncher? whatsApp,
    bool direct = false,
    bool fromCache = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(
            temple: temple ?? _temple(),
            fromCache: fromCache,
            sharer: sharer,
            whatsApp: whatsApp,
            directToWhatsApp: direct,
            reviewPrompter: ReviewPrompter.disabled(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(share);
    await tester.pumpAndSettle();
  }

  Future<void> tapShare(WidgetTester tester) async {
    await tester.tap(share);
    await tester.pump();
  }

  /// share_place events; each carries temple_id only.
  List<Map<String, Object>?> sharePlaces() => [
    for (final e in analytics.events)
      if (e.name == 'share_place') e.parameters,
  ];
  const onePlace = [
    {'temple_id': 'kadri-manjunath'},
  ];

  group('named regression (SHARE-SPEC.md)', () {
    testWidgets('(a) double tap opens exactly one share sheet', (tester) async {
      final sheet = Completer<void>();
      final sharer = FakeTempleSharer(hold: sheet.future);
      await pumpDetail(tester, sharer: sharer);
      await tester.tap(share);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(share);
      await tester.pump();
      expect(sharer.texts, hasLength(1));
      expect(sharePlaces(), onePlace);
      sheet.complete();
      await tester.pump();
    });

    testWidgets('(a) double tap opens WhatsApp exactly once', (tester) async {
      final open = Completer<void>();
      final whatsApp = FakeWhatsAppLauncher(hold: open.future);
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        whatsApp: whatsApp,
        direct: true,
      );
      await tester.tap(share);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(share);
      await tester.pump();
      open.complete();
      await tester.pump();
      expect(whatsApp.texts, hasLength(1));
      expect(sharer.texts, isEmpty);
    });

    testWidgets(
      '(b) WhatsApp not installed: label "Share", one system share, exact text',
      (tester) async {
        final launcher = _UrlLauncher(canWhatsApp: false);
        UrlLauncherPlatform.instance = launcher;
        final sharer = FakeTempleSharer();
        await pumpDetail(
          tester,
          sharer: sharer,
          whatsApp: const UrlLauncherWhatsAppLauncher(),
          direct: true,
        );
        expect(label('Share'), findsOneWidget);
        expect(label('Share on WhatsApp'), findsNothing);
        await tapShare(tester);
        expect(sharer.texts, [
          'Kadri Manjunath Temple\n'
              'Mangaluru, Karnataka\n'
              'Found on Temple Directory India: $_play',
        ]);
        expect(sharer.subjects, ['Kadri Manjunath Temple']);
        expect(launcher.launched, isEmpty);
        expect(sharePlaces(), onePlace);
      },
    );

    testWidgets('(c) empty city: no stray comma', (tester) async {
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        temple: _temple(city: ''),
      );
      await tapShare(tester);
      expect(sharer.texts.single.split('\n'), [
        'Kadri Manjunath Temple',
        'Karnataka',
        'Found on Temple Directory India: $_play',
      ]);
    });

    testWidgets('(d) Sikh place: neutral text, no "darshan"', (tester) async {
      final sharer = FakeTempleSharer();
      final golden = _temple(
        id: 'golden-temple',
        name: 'Harmandir Sahib',
        city: 'Amritsar',
        state: 'Punjab',
        deity: 'Guru Granth Sahib',
        tradition: 'sikh',
      );
      await pumpDetail(tester, sharer: sharer, temple: golden);
      await tapShare(tester);
      expect(sharer.texts.single, _expected(golden));
      expect(sharer.texts.single.toLowerCase(), isNot(contains('darshan')));
      expect(sharer.texts.single.toLowerCase(), isNot(contains('hindu')));
    });
  });

  group('real-user sequences', () {
    testWidgets('1. share once; detail unchanged at the same scroll', (
      tester,
    ) async {
      final sharer = FakeTempleSharer();
      await pumpDetail(tester, sharer: sharer);
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final before = scrollable.position.pixels;
      await tapShare(tester);
      await tester.pumpAndSettle();
      expect(sharer.texts, hasLength(1));
      expect(scrollable.position.pixels, before);
      expect(find.text('How to Reach'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('2. rapid triple tap opens one sheet', (tester) async {
      final sheet = Completer<void>();
      final sharer = FakeTempleSharer(hold: sheet.future);
      await pumpDetail(tester, sharer: sharer);
      for (var i = 0; i < 3; i++) {
        await tester.tap(share);
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(sharer.texts, hasLength(1));
      sheet.complete();
      await tester.pump();
    });

    testWidgets('3. share, back, share again: the guard is released', (
      tester,
    ) async {
      final sharer = FakeTempleSharer();
      await pumpDetail(tester, sharer: sharer);
      await tapShare(tester);
      await tester.pumpAndSettle();
      await tapShare(tester);
      await tester.pumpAndSettle();
      expect(sharer.texts, hasLength(2));
    });

    testWidgets('4. not installed: sheet opens, cancel, no SnackBar', (
      tester,
    ) async {
      final whatsApp = FakeWhatsAppLauncher(installed: false);
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        whatsApp: whatsApp,
        direct: true,
      );
      expect(label('Share'), findsOneWidget);
      await tapShare(tester);
      await tester.pumpAndSettle();
      expect(whatsApp.texts, isEmpty);
      expect(sharer.texts, hasLength(1));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('5. sheet open, app backgrounded and resumed: no 2nd sheet', (
      tester,
    ) async {
      final sheet = Completer<void>();
      final sharer = FakeTempleSharer(hold: sheet.future);
      await pumpDetail(tester, sharer: sharer);
      await tapShare(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tapShare(tester);
      expect(sharer.texts, hasLength(1));
      sheet.complete();
      await tester.pump();
      sharer.hold = null;
      await tapShare(tester);
      expect(sharer.texts, hasLength(2));
    });

    testWidgets('6. reopening the same place: label decided once per open', (
      tester,
    ) async {
      final whatsApp = FakeWhatsAppLauncher();
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        whatsApp: whatsApp,
        direct: true,
      );
      expect(label('Share on WhatsApp'), findsOneWidget);
      expect(whatsApp.checks, 1);
      // Uninstalled mid-screen: the label does not flicker and the tap
      // does not re-check.
      whatsApp.installed = false;
      await tapShare(tester);
      await tester.pumpAndSettle();
      expect(label('Share on WhatsApp'), findsOneWidget);
      expect(whatsApp.checks, 1);

      await tester.pumpWidget(const SizedBox());
      await pumpDetail(
        tester,
        sharer: sharer,
        whatsApp: whatsApp,
        direct: true,
      );
      expect(whatsApp.checks, 2);
      expect(label('Share'), findsOneWidget);
      await tapShare(tester);
      await tester.pumpAndSettle();
      expect(whatsApp.texts, hasLength(1));
      expect(sharer.texts, hasLength(1));
    });

    testWidgets('7a. entry: Temples near me row -> detail -> share -> back', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final sharer = FakeTempleSharer();
      TempleSharer.instance = sharer;
      final place = _temple();
      await tester.pumpWidget(
        MaterialApp(
          home: TemplesNearMeScreen(
            temples: [place],
            location: FakeCoarseLocation(
              permission: CoarsePermission.granted,
              fix: const CoarseFix(latitude: 12.88, longitude: 74.85),
            ),
            districtOf: (_) => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cont = find.byKey(const Key('near-me-continue'));
      if (cont.evaluate().isNotEmpty) {
        await tester.tap(cont);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('near-me-row-kadri-manjunath')));
      await tester.pumpAndSettle();
      expect(find.byType(TempleDetailScreen), findsOneWidget);
      await tester.ensureVisible(share);
      await tester.pumpAndSettle();
      await tapShare(tester);
      await tester.pumpAndSettle();
      expect(sharer.texts, [_expected(place)]);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TemplesNearMeScreen), findsOneWidget);
      expect(find.byType(TempleDetailScreen), findsNothing);
    });

    testWidgets('7b. entry: Home Browse card -> detail -> share -> back', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final sharer = FakeTempleSharer();
      TempleSharer.instance = sharer;
      final place = _temple();
      TempleService.readsBlocked = () => true;
      TempleService.published = [place];
      addTearDown(TempleService.resetSessionForTest);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            adminAuth: FakeAdminAuth(),
            adminToolsEnabled: false,
            templesLoader: () async => [place],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-browse-temples')));
      await tester.pumpAndSettle();
      expect(find.byType(TempleListScreen), findsOneWidget);
      final card = find.byType(TempleBrowseCard).first;
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      await tester.ensureVisible(share);
      await tester.pumpAndSettle();
      await tapShare(tester);
      await tester.pumpAndSettle();
      expect(sharer.texts, [_expected(place)]);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TempleListScreen), findsOneWidget);
    });

    testWidgets('8. no pin: Share still shows and works', (tester) async {
      final sharer = FakeTempleSharer();
      final unpinned = _temple(lat: null, lng: null);
      await pumpDetail(tester, sharer: sharer, temple: unpinned);
      await tapShare(tester);
      expect(sharer.texts, [_expected(unpinned)]);

      // No name either: no Get Directions at all, Share under the location.
      final bare = _temple(name: '', lat: null, lng: null);
      await pumpDetail(tester, sharer: sharer, temple: bare);
      expect(find.byKey(const Key('get-directions-button')), findsNothing);
      expect(share, findsOneWidget);
      await tapShare(tester);
      expect(
        sharer.texts.last,
        'Mangaluru, Karnataka\nFound on Temple Directory India: $_play',
      );
    });

    testWidgets('9. empty city and city == state: no stray comma', (
      tester,
    ) async {
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        temple: _temple(city: 'Delhi', state: 'Delhi'),
      );
      await tapShare(tester);
      expect(sharer.texts.single.split('\n')[1], 'Delhi');
    });

    testWidgets('10. Jain, Buddhist, Sikh: same neutral template', (
      tester,
    ) async {
      final sharer = FakeTempleSharer();
      for (final (name, tradition) in [
        ('Dilwara Temples', 'jain'),
        ('Mahabodhi Temple', 'buddhist'),
        ('Harmandir Sahib', 'sikh'),
      ]) {
        final place = _temple(name: name, tradition: tradition);
        await pumpDetail(tester, sharer: sharer, temple: place);
        await tapShare(tester);
        expect(sharer.texts.last, _expected(place));
      }
    });

    testWidgets('11. offline (cached detail): share still opens', (
      tester,
    ) async {
      final sharer = FakeTempleSharer();
      await pumpDetail(tester, sharer: sharer, fromCache: true);
      expect(find.text('This page may be out of date.'), findsOneWidget);
      await tapShare(tester);
      expect(sharer.texts, hasLength(1));
    });

    testWidgets('12. text scale 2.0 on 360 dp: no overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: Scaffold(
            body: TempleDetailBody(
              temple: _temple(),
              sharer: FakeTempleSharer(),
              whatsApp: FakeWhatsAppLauncher(),
              directToWhatsApp: true,
              reviewPrompter: ReviewPrompter.disabled(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(share);
      await tester.pumpAndSettle();
      expect(label('Share on WhatsApp'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.getRect(share).right, lessThanOrEqualTo(360));
      expect(tester.getRect(share).height, greaterThanOrEqualTo(50));
    });
  });

  group('WhatsApp path (behind kShareDirectToWhatsApp)', () {
    testWidgets('installed: "Share on WhatsApp" opens WhatsApp only', (
      tester,
    ) async {
      final whatsApp = FakeWhatsAppLauncher();
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        whatsApp: whatsApp,
        direct: true,
      );
      expect(label('Share on WhatsApp'), findsOneWidget);
      await tapShare(tester);
      expect(whatsApp.texts, [_expected(_temple())]);
      expect(sharer.texts, isEmpty);
      expect(sharePlaces(), onePlace);
    });

    testWidgets('whatsapp:// fails: wa.me with the encoded text', (
      tester,
    ) async {
      final launcher = _UrlLauncher(
        launches: {'whatsapp': false, 'https': true},
      );
      UrlLauncherPlatform.instance = launcher;
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        whatsApp: const UrlLauncherWhatsAppLauncher(),
        direct: true,
      );
      await tapShare(tester);
      final text = Uri.encodeComponent(_expected(_temple()));
      expect(launcher.launched, [
        'whatsapp://send?text=$text',
        'https://wa.me/?text=$text',
      ]);
      expect(sharer.texts, isEmpty);
    });

    testWidgets('WhatsApp and wa.me fail: system sheet', (tester) async {
      UrlLauncherPlatform.instance = _UrlLauncher();
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        whatsApp: const UrlLauncherWhatsAppLauncher(),
        direct: true,
      );
      await tapShare(tester);
      expect(sharer.texts, hasLength(1));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('WhatsApp throws: system sheet', (tester) async {
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        whatsApp: FakeWhatsAppLauncher(openError: Exception('no activity')),
        direct: true,
      );
      await tapShare(tester);
      expect(sharer.texts, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a throwing install check falls back to "Share"', (
      tester,
    ) async {
      final sharer = FakeTempleSharer();
      await pumpDetail(
        tester,
        sharer: sharer,
        whatsApp: FakeWhatsAppLauncher(checkError: StateError('pm')),
        direct: true,
      );
      expect(label('Share'), findsOneWidget);
      await tapShare(tester);
      expect(sharer.texts, hasLength(1));
    });

    testWidgets('everything fails: one SnackBar, button usable again', (
      tester,
    ) async {
      final sharer = FakeTempleSharer(opens: false);
      await pumpDetail(
        tester,
        sharer: sharer,
        whatsApp: FakeWhatsAppLauncher(opens: false),
        direct: true,
      );
      await tapShare(tester);
      await tester.pump();
      expect(
        find.text(ShareStrings.templeDetailShareUnavailable),
        findsOneWidget,
      );
      sharer.opens = true;
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tapShare(tester);
      expect(sharer.texts, hasLength(2));
    });

    testWidgets('share sheet throws (direct off): SnackBar', (tester) async {
      final sharer = FakeTempleSharer(error: Exception('no share target'));
      await pumpDetail(tester, sharer: sharer);
      await tapShare(tester);
      await tester.pump();
      expect(
        find.text(ShareStrings.templeDetailShareUnavailable),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('default build follows kShareDirectToWhatsApp', (tester) async {
      final whatsApp = FakeWhatsAppLauncher();
      final sharer = FakeTempleSharer();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TempleDetailBody(
              temple: _temple(),
              sharer: sharer,
              whatsApp: whatsApp,
              reviewPrompter: ReviewPrompter.disabled(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(share);
      await tester.pumpAndSettle();
      expect(whatsApp.checks, kShareDirectToWhatsApp ? 1 : 0);
      expect(
        label(kShareDirectToWhatsApp ? 'Share on WhatsApp' : 'Share'),
        findsOneWidget,
      );
      await tapShare(tester);
      expect(sharePlaces(), onePlace);
      expect(
        kShareDirectToWhatsApp ? whatsApp.texts : sharer.texts,
        hasLength(1),
      );
    });
  });
}
