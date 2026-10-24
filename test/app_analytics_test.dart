import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/analytics_client.dart';
import 'package:temple_app/services/analytics_navigator.dart';
import 'package:temple_app/services/analytics_routes.dart';
import 'package:temple_app/services/app_analytics.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);
  tearDown(AppAnalytics.resetForTest);

  test('configure skips the SDK when Firebase is not ready', () async {
    var built = 0;
    await AppAnalytics.configure(
      firebaseReady: false,
      releaseMode: true,
      demoBuild: false,
      adminToolsDefine: false,
      demoAppIdSuffix: false,
      firebaseClient: () {
        built += 1;
        return RecordingAnalyticsClient();
      },
    );
    expect(built, 0);
    expect(AppAnalytics.instance.collectionEnabled, isFalse);
  });

  test('production release enables collection', () async {
    final client = RecordingAnalyticsClient();
    await AppAnalytics.configure(
      firebaseReady: true,
      releaseMode: true,
      demoBuild: false,
      adminToolsDefine: false,
      demoAppIdSuffix: false,
      firebaseClient: () => client,
    );
    expect(client.collection, [true]);
    expect(client.consent, [
      (
        adPersonalizationSignalsConsentGranted: false,
        adUserDataConsentGranted: false,
      ),
    ]);
    expect(AppAnalytics.instance.collectionEnabled, isTrue);
    expect(AppAnalytics.instance.client, same(client));
  });

  test(
    'demo, admin, suffix, and non-release builds disable collection',
    () async {
      final cases = <({bool release, bool demo, bool admin, bool suffix})>[
        (release: true, demo: true, admin: false, suffix: false),
        (release: true, demo: false, admin: true, suffix: false),
        (release: true, demo: false, admin: false, suffix: true),
        (release: false, demo: false, admin: false, suffix: false),
      ];
      for (final flags in cases) {
        final client = RecordingAnalyticsClient();
        await AppAnalytics.configure(
          firebaseReady: true,
          releaseMode: flags.release,
          demoBuild: flags.demo,
          adminToolsDefine: flags.admin,
          demoAppIdSuffix: flags.suffix,
          firebaseClient: () => client,
        );
        expect(client.collection, [false], reason: '$flags');
        expect(client.consent, [
          (
            adPersonalizationSignalsConsentGranted: false,
            adUserDataConsentGranted: false,
          ),
        ], reason: '$flags');
        await AppAnalytics.instance.logScreenView(AnalyticsScreens.home);
        expect(client.screens, isEmpty, reason: '$flags');
        expect(AppAnalytics.instance.collectionEnabled, isFalse);
      }
    },
  );

  test('a failed collection flag does not keep the live client', () async {
    final client = RecordingAnalyticsClient(failCollection: true);
    await AppAnalytics.configure(
      firebaseReady: true,
      releaseMode: true,
      demoBuild: false,
      adminToolsDefine: false,
      demoAppIdSuffix: false,
      firebaseClient: () => client,
    );
    expect(AppAnalytics.instance.collectionEnabled, isFalse);
    await AppAnalytics.instance.logScreenView(AnalyticsScreens.home);
    expect(client.screens, isEmpty);
  });

  test('search logs length and a results flag, not the query text', () async {
    final client = RecordingAnalyticsClient();
    final analytics = AppAnalytics(client: client, collectionEnabled: true);
    const typed = 'meenakshi temple';
    await analytics.logSearch(queryLength: typed.length, hasResults: true);
    await analytics.logSearch(queryLength: 0, hasResults: false);
    expect(client.events, hasLength(1));
    final event = client.events.single;
    expect(event.name, 'search');
    expect(event.parameters, {'query_length': typed.length, 'has_results': 1});
    expect(event.parameters!.values, isNot(contains(typed)));
  });

  test('filter_used logs type and the place or deity name', () async {
    final client = RecordingAnalyticsClient();
    final analytics = AppAnalytics(client: client, collectionEnabled: true);
    await analytics.logFilterTransition(
      previousState: null,
      nextState: 'Tamil Nadu',
      previousDeity: null,
      nextDeity: 'Shiva',
      previousDistrict: 'Chennai',
      nextDistrict: 'Chennai',
    );
    await analytics.logFilterTransition(
      previousState: 'Tamil Nadu',
      nextState: null,
      previousDeity: 'Shiva',
      nextDeity: null,
      previousDistrict: 'Chennai',
      nextDistrict: null,
    );
    await analytics.logFilterUsed(type: 'city', value: 'Madurai');
    expect(client.events.map((event) => event.name), [
      'filter_used',
      'filter_used',
    ]);
    expect(client.events[0].parameters, {
      'type': 'state',
      'value': 'Tamil Nadu',
    });
    expect(client.events[1].parameters, {'type': 'deity', 'value': 'Shiva'});
  });

  test('temple events carry the id and near me carries nothing', () async {
    final client = RecordingAnalyticsClient();
    final analytics = AppAnalytics(client: client, collectionEnabled: true);
    await analytics.logTempleOpened('shore-temple');
    await analytics.logTempleOpened('  ');
    await analytics.logGetDirections('shore-temple');
    await analytics.logTemplesNearMe();
    expect(client.events.map((event) => event.name), [
      'temple_opened',
      'get_directions',
      'temples_near_me',
    ]);
    expect(client.events[0].parameters, {'temple_id': 'shore-temple'});
    expect(client.events[1].parameters, {'temple_id': 'shore-temple'});
    expect(client.events[2].parameters, isNull);
  });

  test('unknown screens are dropped', () async {
    final client = RecordingAnalyticsClient();
    final analytics = AppAnalytics(client: client, collectionEnabled: true);
    await analytics.logScreenView('home');
    await analytics.logScreenView('/search?q=secret');
    expect(client.screens, ['home']);
  });

  testWidgets('temple route logs the screen and the id', (tester) async {
    final client = RecordingAnalyticsClient();
    AppAnalytics.resetForTest(
      AppAnalytics(client: client, collectionEnabled: true),
    );
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [AnalyticsNavigatorObserver()],
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  namedAnalyticsRoute<void>(
                    name: AnalyticsScreens.templeDetail,
                    arguments: 'shore-temple',
                    builder: (_) => const Text('detail'),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(client.screens, [AnalyticsScreens.templeDetail]);
    expect(client.events.single.parameters, {'temple_id': 'shore-temple'});
  });

  testWidgets('temples near me logs no reading', (tester) async {
    final client = RecordingAnalyticsClient();
    AppAnalytics.resetForTest(
      AppAnalytics(client: client, collectionEnabled: true),
    );
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [AnalyticsNavigatorObserver()],
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  namedAnalyticsRoute<void>(
                    name: AnalyticsScreens.templesNearMe,
                    arguments: const {
                      'latitude': 12.9716,
                      'longitude': 77.5946,
                    },
                    builder: (_) => const Text('near'),
                  ),
                );
              },
              child: const Text('Near'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Near'));
    await tester.pumpAndSettle();
    expect(client.screens, [AnalyticsScreens.templesNearMe]);
    expect(client.events, hasLength(1));
    expect(client.events.single.name, 'temples_near_me');
    expect(client.events.single.parameters, isNull);
    final dumped = client.events.single.toString();
    expect(dumped, isNot(contains('12.9716')));
    expect(dumped, isNot(contains('77.5946')));
  });

  test('manifest keeps collection off until the production process enables it', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      manifest,
      contains('android:name="firebase_analytics_collection_enabled"'),
    );
    expect(
      manifest,
      contains('android:name="google_analytics_adid_collection_enabled"'),
    );
    expect(
      manifest,
      contains('android:name="google_analytics_ssaid_collection_enabled"'),
    );
    expect(
      manifest,
      contains(
        'android:name="google_analytics_default_allow_ad_personalization_signals"',
      ),
    );
    expect(
      RegExp(
        r'android:name="google_analytics_default_allow_ad_personalization_signals"\s+android:value="false"',
      ).hasMatch(manifest),
      isTrue,
    );
    expect(
      RegExp(
        r'android:name="firebase_analytics_collection_enabled"\s+android:value="false"',
      ).hasMatch(manifest),
      isTrue,
    );
  });
}

class RecordingAnalyticsClient implements AnalyticsClient {
  RecordingAnalyticsClient({this.failCollection = false});

  final bool failCollection;
  final collection = <bool>[];
  final consent =
      <
        ({
          bool adPersonalizationSignalsConsentGranted,
          bool adUserDataConsentGranted,
        })
      >[];
  final screens = <String>[];
  final events = <({String name, Map<String, Object>? parameters})>[];

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collection.add(enabled);
    if (failCollection) throw StateError('collection flag failed');
  }

  @override
  Future<void> setConsent({
    required bool adPersonalizationSignalsConsentGranted,
    required bool adUserDataConsentGranted,
  }) async {
    consent.add((
      adPersonalizationSignalsConsentGranted:
          adPersonalizationSignalsConsentGranted,
      adUserDataConsentGranted: adUserDataConsentGranted,
    ));
  }

  @override
  Future<void> logScreenView({required String screenName}) async {
    screens.add(screenName);
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    events.add((name: name, parameters: parameters));
  }
}
