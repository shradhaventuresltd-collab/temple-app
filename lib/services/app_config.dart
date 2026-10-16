import 'dart:async';

import 'package:flutter/foundation.dart';

/// Remote Config parameter names. Deployer owns the console template.
///
/// In-app defaults below are what a first launch and a failed fetch use.
/// Nothing here writes the console or production.
abstract final class RemoteConfigKeys {
  static const String killSwitch = 'kill_switch';
  static const String maintenanceMessage = 'maintenance_message';
  static const String minSupportedBuild = 'min_supported_build';
  static const String recommendedBuild = 'recommended_build';
  static const String contentVersion = 'content_version';
  static const String adsEnabled = 'ff_ads_enabled';
  static const String newFilters = 'ff_new_filters';

  /// Feature flags use the `ff_` prefix. [adsEnabled] stays on so today's
  /// ad startup is unchanged. [newFilters] stays off until a deployer
  /// turns that flag on; browse chips are still the compiled list.
  static const Map<String, Object> defaults = {
    killSwitch: false,
    maintenanceMessage: '',
    minSupportedBuild: 1,
    recommendedBuild: 1,
    contentVersion: 0,
    adsEnabled: true,
    newFilters: false,
  };
}

/// How long the app waits before asking Remote Config again.
///
/// One hour in every build, including debug. A shorter interval would
/// refetch during a session and is not what the tester build uses.
const Duration kRemoteConfigMinimumFetchInterval = Duration(hours: 1);

/// Typed view of the parameters the app reads.
///
/// [AppConfig.defaults] is the offline and first-launch value. A background
/// fetch does not replace this snapshot mid-session except for [killSwitch].
class AppConfig {
  const AppConfig({
    this.killSwitch = false,
    this.maintenanceMessage = '',
    this.minSupportedBuild = 1,
    this.recommendedBuild = 1,
    this.contentVersion = 0,
    this.adsEnabled = true,
    this.newFiltersEnabled = false,
  });

  static const AppConfig defaults = AppConfig();

  /// True shows a maintenance screen and skips directory reads.
  final bool killSwitch;

  /// Banner text while the app is open. Empty shows nothing.
  final String maintenanceMessage;

  /// Builds below this are blocked. The update screen is a later change.
  final int minSupportedBuild;

  /// Builds below this get a soft nudge. The nudge is a later change.
  final int recommendedBuild;

  /// Hint a publisher bumps when temple content changes. Not a Firestore field.
  final int contentVersion;

  /// `ff_ads_enabled`. Default true keeps today's ad startup.
  final bool adsEnabled;

  /// `ff_new_filters`. Default false. Browse chips stay compiled until a
  /// later change reads this flag.
  final bool newFiltersEnabled;

  AppConfig copyWith({
    bool? killSwitch,
    String? maintenanceMessage,
    int? minSupportedBuild,
    int? recommendedBuild,
    int? contentVersion,
    bool? adsEnabled,
    bool? newFiltersEnabled,
  }) {
    return AppConfig(
      killSwitch: killSwitch ?? this.killSwitch,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      minSupportedBuild: minSupportedBuild ?? this.minSupportedBuild,
      recommendedBuild: recommendedBuild ?? this.recommendedBuild,
      contentVersion: contentVersion ?? this.contentVersion,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      newFiltersEnabled: newFiltersEnabled ?? this.newFiltersEnabled,
    );
  }
}

/// Plugin surface [AppConfigController] needs. Tests pass a fake.
abstract class RemoteConfigClient {
  Future<void> setDefaults(Map<String, Object> defaults);

  Future<void> setSettings({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  });

  Future<void> activate();

  Future<bool> fetchAndActivate();

  bool getBool(String key);

  int getInt(String key);

  String getString(String key);
}

/// Applies cached Remote Config, then fetches without blocking the first frame.
class RemoteConfigStartup {
  const RemoteConfigStartup({required this.ready, required this.fetch});

  /// Completes after defaults and the last activated cache are in memory.
  final Future<void> ready;

  /// The unawaited fetch. A failure leaves [ready]'s snapshot in place.
  final Future<void> fetch;
}

RemoteConfigStartup startRemoteConfig(AppConfigController controller) {
  final ready = controller.activateCachedOrDefaults();
  final fetch = ready.then((_) => controller.fetchAndActivateInBackground());
  return RemoteConfigStartup(ready: ready, fetch: fetch);
}

/// In-memory config for this process.
///
/// Construct with a null [client] when Firebase is not initialised. That
/// path never touches the Remote Config plugin.
class AppConfigController extends ChangeNotifier {
  AppConfigController({
    this.client,
    AppConfig? initial,
    this.minimumFetchInterval = kRemoteConfigMinimumFetchInterval,
    this.fetchTimeout = const Duration(seconds: 3),
    this.localActivateTimeout = const Duration(seconds: 2),
  }) : snapshot = initial ?? AppConfig.defaults;

  final RemoteConfigClient? client;

  /// Release interval is one hour. See [remoteConfigMinimumFetchInterval].
  final Duration minimumFetchInterval;

  /// Cap around `fetchAndActivate`, matching the splash budget in main.
  final Duration fetchTimeout;

  /// Cap around `setDefaults` and `activate` so a stuck plugin cannot hold
  /// the first frame. A timeout keeps [AppConfig.defaults].
  final Duration localActivateTimeout;

  AppConfig snapshot;

  AppConfig _read(RemoteConfigClient remote) {
    return AppConfig(
      killSwitch: remote.getBool(RemoteConfigKeys.killSwitch),
      maintenanceMessage: remote.getString(RemoteConfigKeys.maintenanceMessage),
      minSupportedBuild: remote.getInt(RemoteConfigKeys.minSupportedBuild),
      recommendedBuild: remote.getInt(RemoteConfigKeys.recommendedBuild),
      contentVersion: remote.getInt(RemoteConfigKeys.contentVersion),
      adsEnabled: remote.getBool(RemoteConfigKeys.adsEnabled),
      newFiltersEnabled: remote.getBool(RemoteConfigKeys.newFilters),
    );
  }

  /// `setDefaults`, then activate whatever was fetched last time.
  ///
  /// Does not fetch. Call this before [runApp]. A missing client, a timeout,
  /// or a throw leaves [AppConfig.defaults] and returns.
  Future<void> activateCachedOrDefaults() async {
    final remote = client;
    if (remote == null) return;
    try {
      await _activateLocal(remote).timeout(localActivateTimeout);
    } catch (e, st) {
      debugPrint('Remote Config defaults failed: $e\n$st');
      snapshot = AppConfig.defaults;
      notifyListeners();
    }
  }

  Future<void> _activateLocal(RemoteConfigClient remote) async {
    await remote.setSettings(
      fetchTimeout: fetchTimeout,
      minimumFetchInterval: minimumFetchInterval,
    );
    await remote.setDefaults(RemoteConfigKeys.defaults);
    await remote.activate();
    snapshot = _read(remote);
    notifyListeners();
  }

  /// Fetch and activate for the next launch.
  ///
  /// [killSwitch] is applied as soon as the fetch returns so a bad release
  /// can be stopped without a restart. Other keys stay on the snapshot this
  /// process already activated, so the UI does not flip mid-session.
  Future<void> fetchAndActivateInBackground() async {
    final remote = client;
    if (remote == null) return;
    final before = snapshot;
    try {
      await remote.fetchAndActivate().timeout(fetchTimeout);
      final fetched = _read(remote);
      if (fetched.killSwitch == before.killSwitch) return;
      snapshot = before.copyWith(
        killSwitch: fetched.killSwitch,
        maintenanceMessage: fetched.maintenanceMessage,
      );
      notifyListeners();
    } catch (e, st) {
      debugPrint('Remote Config fetch failed: $e\n$st');
    }
  }
}
