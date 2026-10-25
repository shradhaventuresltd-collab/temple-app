import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/app_config.dart';
import 'package:temple_app/services/firebase_ready.dart';
import 'package:temple_app/services/firebase_remote_config_gateway.dart';

void main() {
  test('in-app defaults match the tester-build contract', () {
    expect(RemoteConfigKeys.defaults, {
      'kill_switch': false,
      'maintenance_message': '',
      'min_supported_build': 1,
      'recommended_build': 1,
      'content_version': 0,
      'ff_ads_enabled': true,
      'ff_new_filters': false,
    });
    expect(RemoteConfigKeys.defaults.containsKey('app_enabled'), isFalse);
    expect(RemoteConfigKeys.defaults.containsKey('maintenance'), isFalse);
    expect(AppConfig.defaults.killSwitch, isFalse);
    expect(AppConfig.defaults.maintenanceMessage, isEmpty);
    expect(AppConfig.defaults.minSupportedBuild, 1);
    expect(AppConfig.defaults.recommendedBuild, 1);
    expect(AppConfig.defaults.contentVersion, 0);
    expect(AppConfig.defaults.adsEnabled, isTrue);
    expect(AppConfig.defaults.newFiltersEnabled, isFalse);
  });

  test('fetch interval is one hour', () {
    expect(kRemoteConfigMinimumFetchInterval, const Duration(hours: 1));
  });

  test('a missing Firebase app does not construct Remote Config', () {
    expect(firebaseAppsReady(), isFalse);
    expect(remoteConfigClientIfReady(firebaseReady: false), isNull);
    expect(remoteConfigClientIfReady(firebaseReady: true), isNull);
  });

  test('startup uses defaults and does not wait for the fetch', () async {
    final client = _FakeRemoteConfig()..hangFetch = Completer<bool>();
    final config = AppConfigController(
      client: client,
      minimumFetchInterval: const Duration(hours: 1),
      fetchTimeout: const Duration(seconds: 3),
    );
    final startup = startRemoteConfig(config);

    await startup.ready;

    expect(client.defaults, RemoteConfigKeys.defaults);
    expect(client.minimumFetchInterval, const Duration(hours: 1));
    expect(client.fetchTimeout, const Duration(seconds: 3));
    expect(client.activateCalls, 1);
    expect(config.snapshot.killSwitch, isFalse);
    expect(config.snapshot.maintenanceMessage, isEmpty);

    var fetchDone = false;
    unawaited(startup.fetch.whenComplete(() => fetchDone = true));
    await Future<void>.delayed(Duration.zero);
    expect(fetchDone, isFalse);
    expect(client.fetchCalls, 1);

    client.hangFetch!.complete(true);
    await startup.fetch;
    expect(fetchDone, isTrue);
  });

  test('a failed or timed-out fetch keeps the defaults', () async {
    final failing = _FakeRemoteConfig()..fetchError = StateError('offline');
    final config = AppConfigController(client: failing);
    await config.activateCachedOrDefaults();
    await config.fetchAndActivateInBackground();
    expect(config.snapshot.killSwitch, isFalse);
    expect(config.snapshot.minSupportedBuild, 1);

    final hung = _FakeRemoteConfig()..hangFetch = Completer<bool>();
    final slow = AppConfigController(
      client: hung,
      fetchTimeout: const Duration(milliseconds: 20),
    );
    await slow.activateCachedOrDefaults();
    await slow.fetchAndActivateInBackground();
    expect(slow.snapshot, isA<AppConfig>());
    expect(slow.snapshot.killSwitch, isFalse);
    expect(slow.snapshot.maintenanceMessage, isEmpty);
  });

  test('a stuck setDefaults falls back to defaults and returns', () async {
    final client = _FakeRemoteConfig()..hangDefaults = Completer<void>();
    final config = AppConfigController(
      client: client,
      localActivateTimeout: const Duration(milliseconds: 20),
    );
    await config.activateCachedOrDefaults();
    expect(config.snapshot.killSwitch, isFalse);
    expect(config.snapshot.adsEnabled, isTrue);
  });

  test('the background fetch cap is one minute, not three seconds', () {
    expect(AppConfigController().fetchTimeout, const Duration(minutes: 1));
  });

  test('startup awaits the local activate and not the one-minute fetch', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('await remoteConfigStartup.ready'));
    expect(source, contains('unawaited(remoteConfigStartup.fetch)'));
    expect(
      RegExp(r'await\s+remoteConfigStartup\.fetch\b').hasMatch(source),
      isFalse,
    );
  });

  test('kill switch and min build apply on fetch; other keys wait', () async {
    final client = _FakeRemoteConfig();
    final config = AppConfigController(client: client);
    await config.activateCachedOrDefaults();
    expect(config.snapshot.minSupportedBuild, 1);

    client.fetched = {
      RemoteConfigKeys.killSwitch: true,
      RemoteConfigKeys.maintenanceMessage: 'Closed for the procession',
      RemoteConfigKeys.minSupportedBuild: 40,
      RemoteConfigKeys.recommendedBuild: 41,
      RemoteConfigKeys.contentVersion: 7,
      RemoteConfigKeys.adsEnabled: false,
      RemoteConfigKeys.newFilters: true,
    };
    await config.fetchAndActivateInBackground();

    expect(config.snapshot.killSwitch, isTrue);
    expect(config.snapshot.maintenanceMessage, 'Closed for the procession');
    expect(config.snapshot.minSupportedBuild, 40);
    expect(config.snapshot.recommendedBuild, 1);
    expect(config.snapshot.contentVersion, 0);
    expect(config.snapshot.adsEnabled, isTrue);
    expect(config.snapshot.newFiltersEnabled, isFalse);

    final nextLaunch = AppConfigController(client: client);
    await nextLaunch.activateCachedOrDefaults();
    expect(nextLaunch.snapshot.killSwitch, isTrue);
    expect(nextLaunch.snapshot.maintenanceMessage, 'Closed for the procession');
    expect(nextLaunch.snapshot.minSupportedBuild, 40);
    expect(nextLaunch.snapshot.recommendedBuild, 41);
    expect(nextLaunch.snapshot.contentVersion, 7);
    expect(nextLaunch.snapshot.adsEnabled, isFalse);
    expect(nextLaunch.snapshot.newFiltersEnabled, isTrue);
  });

  test('min build applies when the kill switch does not change', () async {
    final client = _FakeRemoteConfig();
    final config = AppConfigController(client: client);
    await config.activateCachedOrDefaults();
    client.fetched = {RemoteConfigKeys.minSupportedBuild: 12};
    await config.fetchAndActivateInBackground();
    expect(config.snapshot.killSwitch, isFalse);
    expect(config.snapshot.minSupportedBuild, 12);
    expect(config.snapshot.recommendedBuild, 1);
    expect(config.snapshot.adsEnabled, isTrue);
    expect(config.snapshot.newFiltersEnabled, isFalse);
  });

  test('a cached kill switch is active before the fetch', () async {
    final client = _FakeRemoteConfig()
      ..activated = {
        RemoteConfigKeys.killSwitch: true,
        RemoteConfigKeys.maintenanceMessage: 'Servers are paused',
      };
    final config = AppConfigController(client: client);
    await config.activateCachedOrDefaults();
    expect(config.snapshot.killSwitch, isTrue);
    expect(config.snapshot.maintenanceMessage, 'Servers are paused');
    expect(client.fetchCalls, 0);
  });

  test('no client never calls the plugin and stays on defaults', () async {
    final config = AppConfigController();
    final startup = startRemoteConfig(config);
    await startup.ready;
    await startup.fetch;
    expect(config.snapshot.killSwitch, isFalse);
    expect(config.snapshot.maintenanceMessage, isEmpty);
  });
}

class _FakeRemoteConfig implements RemoteConfigClient {
  Map<String, Object> defaults = {};
  Map<String, Object> activated = {};
  Map<String, Object> fetched = {};
  Duration? fetchTimeout;
  Duration? minimumFetchInterval;
  int activateCalls = 0;
  int fetchCalls = 0;
  Completer<bool>? hangFetch;
  Completer<void>? hangDefaults;
  Object? fetchError;

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    final hang = hangDefaults;
    if (hang != null) await hang.future;
    this.defaults = Map<String, Object>.from(defaults);
  }

  @override
  Future<void> setSettings({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) async {
    this.fetchTimeout = fetchTimeout;
    this.minimumFetchInterval = minimumFetchInterval;
  }

  @override
  Future<void> activate() async {
    activateCalls += 1;
  }

  @override
  Future<bool> fetchAndActivate() async {
    fetchCalls += 1;
    final hang = hangFetch;
    if (hang != null) await hang.future;
    final error = fetchError;
    if (error != null) throw error;
    activated = {...activated, ...fetched};
    return true;
  }

  Object? _value(String key) {
    if (activated.containsKey(key)) return activated[key];
    return defaults[key];
  }

  @override
  bool getBool(String key) => _value(key) == true;

  @override
  int getInt(String key) {
    final value = _value(key);
    if (value is int) return value;
    return 0;
  }

  @override
  String getString(String key) {
    final value = _value(key);
    if (value is String) return value;
    return '';
  }
}
