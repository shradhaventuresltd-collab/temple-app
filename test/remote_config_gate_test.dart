import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/main.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/maintenance_screen.dart';
import 'package:temple_app/screens/policy_acceptance_gate.dart';
import 'package:temple_app/services/app_config.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('kill switch shows maintenance and skips reads and ads', (
    tester,
  ) async {
    var loads = 0;
    var ads = 0;
    final config = AppConfigController(
      initial: const AppConfig(
        killSwitch: true,
        maintenanceMessage: 'Closed for the procession',
      ),
    );

    await tester.pumpWidget(
      TempleDirectoryApp(
        acceptanceStore: _AcceptedStore(),
        initializeFirebase: () async => false,
        initializeAds: () async {
          ads += 1;
        },
        templesLoader: () async {
          loads += 1;
          return [_temple];
        },
        appConfig: config,
        onExitApp: () {},
        launchPolicyUrl: (_) async => true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('maintenance-screen')), findsOneWidget);
    expect(find.text('Closed for the procession'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(PolicyAcceptanceGate), findsNothing);
    expect(loads, 0);
    expect(ads, 0);
  });

  testWidgets('maintenance message is a banner and the directory still loads', (
    tester,
  ) async {
    var loads = 0;
    final config = AppConfigController(
      initial: const AppConfig(maintenanceMessage: 'New temples tonight'),
    );

    await tester.pumpWidget(
      TempleDirectoryApp(
        acceptanceStore: _AcceptedStore(),
        initializeFirebase: () async => false,
        initializeAds: () async {},
        templesLoader: () async {
          loads += 1;
          return [_temple];
        },
        appConfig: config,
        onExitApp: () {},
        launchPolicyUrl: (_) async => true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const Key('maintenance-message-banner')), findsOneWidget);
    expect(find.text('New temples tonight'), findsOneWidget);
    expect(find.byType(MaintenanceScreen), findsNothing);
    expect(loads, 1);
  });

  testWidgets('defaults open Home and do not show a maintenance banner', (
    tester,
  ) async {
    var ads = 0;
    await tester.pumpWidget(
      TempleDirectoryApp(
        acceptanceStore: _AcceptedStore(),
        initializeFirebase: () async => false,
        initializeAds: () async {
          ads += 1;
        },
        templesLoader: () async => [_temple],
        onExitApp: () {},
        launchPolicyUrl: (_) async => true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const Key('maintenance-message-banner')), findsNothing);
    expect(find.byType(MaintenanceScreen), findsNothing);
    expect(ads, 1);
  });

  testWidgets('ff_ads_enabled false skips ad startup', (tester) async {
    var ads = 0;
    final config = AppConfigController(
      initial: const AppConfig(adsEnabled: false),
    );
    await tester.pumpWidget(
      TempleDirectoryApp(
        acceptanceStore: _AcceptedStore(),
        initializeFirebase: () async => false,
        initializeAds: () async {
          ads += 1;
        },
        templesLoader: () async => [_temple],
        appConfig: config,
        onExitApp: () {},
        launchPolicyUrl: (_) async => true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(ads, 0);
  });

  testWidgets('a fetch that raises the kill switch replaces Home', (
    tester,
  ) async {
    var loads = 0;
    final client = _GateRemoteConfig();
    final config = AppConfigController(client: client);
    await config.activateCachedOrDefaults();

    await tester.pumpWidget(
      TempleDirectoryApp(
        acceptanceStore: _AcceptedStore(),
        initializeFirebase: () async => false,
        initializeAds: () async {},
        templesLoader: () async {
          loads += 1;
          return [_temple];
        },
        appConfig: config,
        onExitApp: () {},
        launchPolicyUrl: (_) async => true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(loads, 1);

    client.fetched = {
      RemoteConfigKeys.killSwitch: true,
      RemoteConfigKeys.maintenanceMessage: 'Paused',
    };
    await config.fetchAndActivateInBackground();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('maintenance-screen')), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(loads, 1);
  });
}

class _AcceptedStore implements PolicyAcceptanceStore {
  @override
  Future<PolicyAcceptance?> read() async {
    return PolicyAcceptance(
      version: PolicyConfig.currentVersion,
      acceptedAt: DateTime.utc(2026, 10, 14),
    );
  }

  @override
  Future<void> write(PolicyAcceptance acceptance) async {}
}

final _temple = Temple(
  name: 'Meenakshi Amman Temple',
  state: 'Tamil Nadu',
  city: 'Madurai',
  deity: 'Devi',
  imageUrl: '',
  description: 'A historic temple.',
  story: 'Story',
  location: 'Madurai, Tamil Nadu',
  timings: '6am–9pm',
  specialities: const [],
);

class _GateRemoteConfig implements RemoteConfigClient {
  Map<String, Object> defaults = {};
  Map<String, Object> activated = {};
  Map<String, Object> fetched = {};

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    this.defaults = Map<String, Object>.from(defaults);
  }

  @override
  Future<void> setSettings({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) async {}

  @override
  Future<void> activate() async {}

  @override
  Future<bool> fetchAndActivate() async {
    activated = {...activated, ...fetched};
    return true;
  }

  Object? _value(String key) => activated[key] ?? defaults[key];

  @override
  bool getBool(String key) => _value(key) == true;

  @override
  int getInt(String key) {
    final value = _value(key);
    return value is int ? value : 0;
  }

  @override
  String getString(String key) {
    final value = _value(key);
    return value is String ? value : '';
  }
}
