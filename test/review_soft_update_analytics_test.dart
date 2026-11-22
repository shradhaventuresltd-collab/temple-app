// Satyavrat's PR 148 r1 follow-ups: share_place / review_requested
// analytics, and no review ask on the Home open that shows the soft-update
// banner (the session-3 ask is deferred, not spent).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/main.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/services/analytics_client.dart';
import 'package:temple_app/services/app_analytics.dart';
import 'package:temple_app/services/app_config.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';
import 'package:temple_app/services/review_prompt.dart';
import 'package:temple_app/services/update_nudge_store.dart';

import 'helpers/fake_review.dart';

class _Events implements AnalyticsClient {
  final events = <({String name, Map<String, Object>? parameters})>[];

  List<String> get names => [for (final e in events) e.name];

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

class _AcceptedStore implements PolicyAcceptanceStore {
  @override
  Future<PolicyAcceptance?> read() async => PolicyAcceptance(
    version: PolicyConfig.currentVersion,
    acceptedAt: DateTime.utc(2026, 10, 14),
  );

  @override
  Future<void> write(PolicyAcceptance acceptance) async {}
}

const _place = Temple(
  id: 'meenakshi-amman',
  name: 'Meenakshi Amman Temple',
  state: 'Tamil Nadu',
  city: 'Madurai',
  deity: 'Devi',
  imageUrl: '',
  description: '',
  story: '',
  location: 'Madurai, Tamil Nadu',
  timings: null,
  specialities: [],
  latitude: 9.9195,
  longitude: 78.1193,
);

void main() {
  late _Events events;
  late FakeReviewClient client;
  late MemoryReviewPromptStore store;
  late AppAnalytics analytics;
  final day = DateTime.utc(2026, 11, 13, 6);

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    events = _Events();
    analytics = AppAnalytics(client: events, collectionEnabled: true);
    client = FakeReviewClient();
    store = MemoryReviewPromptStore();
  });

  tearDown(AppAnalytics.resetForTest);

  ReviewPrompter prompter({DateTime? now}) => ReviewPrompter(
    client: client,
    store: store,
    now: () => now ?? day,
    analytics: analytics,
  );

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  group('AppAnalytics events', () {
    test('share_place carries temple_id only', () async {
      await analytics.logSharePlace('meenakshi-amman');
      await analytics.logSharePlace('  ');
      expect(events.events.single.name, 'share_place');
      expect(events.events.single.parameters, {'temple_id': 'meenakshi-amman'});
    });

    test('review_requested carries an allowlisted trigger only', () async {
      for (final t in [
        'session3',
        'directions',
        'save',
        'Kadri Manjunath Temple',
        '',
      ]) {
        await analytics.logReviewRequested(t);
      }
      expect(events.names, List.filled(3, 'review_requested'));
      expect(
        [for (final e in events.events) e.parameters],
        [
          {'trigger': 'session3'},
          {'trigger': 'directions'},
          {'trigger': 'save'},
        ],
      );
    });

    test('trigger names', () {
      expect(reviewTriggerAnalyticsName(ReviewTrigger.session), 'session3');
      expect(
        reviewTriggerAnalyticsName(ReviewTrigger.directions),
        'directions',
      );
      expect(reviewTriggerAnalyticsName(ReviewTrigger.save), 'save');
    });
  });

  group('review_requested is logged only when Play is asked', () {
    test('session 3 logs session3 once', () async {
      for (var i = 0; i < 4; i++) {
        await prompter().onSessionStart();
      }
      await flush();
      expect(client.requests, 1);
      expect(events.events.single.parameters, {'trigger': 'session3'});
    });

    test('directions and save log their trigger', () async {
      store.sessionCount = 2;
      expect(
        await prompter().onPositiveMoment(ReviewTrigger.directions),
        isTrue,
      );
      store.lastPrompt = day.subtract(const Duration(days: 31));
      expect(await prompter().onPositiveMoment(ReviewTrigger.save), isTrue);
      await flush();
      expect(
        [for (final e in events.events) e.parameters!['trigger']],
        ['directions', 'save'],
      );
    });

    test('nothing logged when blocked: first session, cooldown, '
        'unavailable, disabled, in flight', () async {
      store.sessionCount = 1;
      await prompter().onPositiveMoment(ReviewTrigger.directions);
      store
        ..sessionCount = 5
        ..lastPrompt = day.subtract(const Duration(days: 3));
      await prompter().onPositiveMoment(ReviewTrigger.directions);
      store.lastPrompt = null;
      client.available = false;
      await prompter().onPositiveMoment(ReviewTrigger.directions);
      await ReviewPrompter.disabled().onPositiveMoment(ReviewTrigger.save);
      client.availableError = StateError('play');
      client.available = true;
      await prompter().onPositiveMoment(ReviewTrigger.directions);
      await flush();
      expect(client.requests, 0);
      expect(events.events, isEmpty);
    });
  });

  group('soft-update banner defers the session ask', () {
    test(
      'banner on open 3: no ask, owed; open 4 asks; open 5 does not',
      () async {
        store.sessionCount = 2;
        expect(
          await prompter().onSessionStart(softUpdateShown: Future.value(true)),
          isFalse,
        );
        expect(client.availabilityChecks, 0);
        expect(store.sessionCount, 3);
        expect(store.sessionDeferred, isTrue);

        expect(await prompter().onSessionStart(), isTrue);
        expect(store.sessionDeferred, isFalse);
        expect(await prompter().onSessionStart(), isFalse);
        await flush();
        expect(client.requests, 1);
        expect(events.events.single.parameters, {'trigger': 'session3'});
      },
    );

    test('banner offered but not shown (already shown today): asks', () async {
      store.sessionCount = 2;
      expect(
        await prompter().onSessionStart(softUpdateShown: Future.value(false)),
        isTrue,
      );
    });

    test('banner again on the next open: still owed, asks after', () async {
      store.sessionCount = 2;
      await prompter().onSessionStart(softUpdateShown: Future.value(true));
      await prompter().onSessionStart(softUpdateShown: Future.value(true));
      expect(client.requests, 0);
      expect(store.sessionDeferred, isTrue);
      expect(await prompter().onSessionStart(), isTrue);
    });

    test('a failing decision counts as no banner', () async {
      store.sessionCount = 2;
      expect(
        await prompter().onSessionStart(
          softUpdateShown: Future<bool>(() => throw StateError('prefs')),
        ),
        isTrue,
      );
    });

    test('banner on open 2 records nothing; open 3 asks as usual', () async {
      store.sessionCount = 1;
      await prompter().onSessionStart(softUpdateShown: Future.value(true));
      expect(store.sessionDeferred, isFalse);
      expect(await prompter().onSessionStart(), isTrue);
    });

    test('existing installs past session 3 are not asked on upgrade', () async {
      store.sessionCount = 7;
      expect(await prompter().onSessionStart(), isFalse);
      expect(client.availabilityChecks, 0);
    });

    test('a deferred ask still respects the cooldown', () async {
      store
        ..sessionCount = 3
        ..sessionDeferred = true
        ..lastPrompt = day.subtract(const Duration(days: 2));
      expect(await prompter().onSessionStart(), isFalse);
      expect(store.sessionDeferred, isFalse);
    });

    test('SharedPreferences round-trips the deferred flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = SharedPreferencesReviewPromptStore();
      expect(await prefs.readSessionDeferred(), isFalse);
      await prefs.writeSessionDeferred(true);
      expect(await prefs.readSessionDeferred(), isTrue);
      await prefs.writeSessionDeferred(false);
      final raw = await SharedPreferences.getInstance();
      expect(raw.containsKey(ReviewPromptKeys.sessionDeferred), isFalse);
    });
  });

  group('app wiring', () {
    Future<void> open(
      WidgetTester tester, {
      required MemoryUpdateNudgeStore nudge,
      required DateTime now,
      int build = 3,
    }) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        TempleDirectoryApp(
          acceptanceStore: _AcceptedStore(),
          initializeFirebase: () async => false,
          initializeAds: () async {},
          templesLoader: () async => [_place],
          appConfig: AppConfigController(
            initial: const AppConfig(minSupportedBuild: 1, recommendedBuild: 6),
          ),
          installedBuildNumber: build,
          nudgeStore: nudge,
          now: () => now,
          onExitApp: () {},
          launchPolicyUrl: (_) async => true,
          adminToolsEnabled: false,
          reviewPrompter: prompter(now: now),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    }

    testWidgets('open 3 shows the banner: no ask; open 4 (no banner) asks', (
      tester,
    ) async {
      store.sessionCount = 2;
      final nudge = MemoryUpdateNudgeStore();
      await open(tester, nudge: nudge, now: day);
      expect(find.byKey(const Key('soft-update-nudge')), findsOneWidget);
      expect(store.sessionCount, 3);
      expect(client.requests, 0);
      expect(store.sessionDeferred, isTrue);

      // Same UTC day: the banner is not shown again, so the ask runs.
      await open(tester, nudge: nudge, now: day.add(const Duration(hours: 4)));
      expect(find.byKey(const Key('soft-update-nudge')), findsNothing);
      expect(store.sessionCount, 4);
      expect(client.requests, 1);
      expect(events.events.single.name, 'review_requested');
    });

    testWidgets('open 3 with the banner already shown today asks', (
      tester,
    ) async {
      store.sessionCount = 2;
      final nudge = MemoryUpdateNudgeStore()..day = '2026-11-13';
      await open(tester, nudge: nudge, now: day);
      expect(find.byKey(const Key('soft-update-nudge')), findsNothing);
      expect(client.requests, 1);
    });

    testWidgets('a current build (no banner offered) asks on open 3', (
      tester,
    ) async {
      store.sessionCount = 2;
      await open(tester, nudge: MemoryUpdateNudgeStore(), now: day, build: 6);
      expect(client.requests, 1);
    });
  });

  group('share_place from the detail page', () {
    testWidgets('one event per launch; a guarded double tap logs once', (
      tester,
    ) async {
      AppAnalytics.resetForTest(analytics);
      final sheet = Completer<void>();
      final sharer = FakeTempleSharer(hold: sheet.future);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TempleDetailBody(
              temple: _place,
              sharer: sharer,
              reviewPrompter: ReviewPrompter.disabled(),
            ),
          ),
        ),
      );
      await tester.pump();
      final share = find.byKey(const Key('detail-share-button'));
      await tester.ensureVisible(share);
      await tester.pumpAndSettle();
      await tester.tap(share);
      await tester.pump();
      await tester.tap(share);
      await tester.pump();
      expect(sharer.texts, hasLength(1));
      expect(events.names.where((n) => n == 'share_place'), hasLength(1));
      sheet.complete();
      await tester.pumpAndSettle();
      sharer.hold = null;
      await tester.tap(share);
      await tester.pumpAndSettle();
      final shares = [
        for (final e in events.events)
          if (e.name == 'share_place') e.parameters,
      ];
      expect(shares, [
        {'temple_id': 'meenakshi-amman'},
        {'temple_id': 'meenakshi-amman'},
      ]);
    });
  });
}
