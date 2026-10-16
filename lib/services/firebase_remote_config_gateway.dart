import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:temple_app/services/app_config.dart';
import 'package:temple_app/services/firebase_ready.dart';

/// Remote Config client, or null when Firebase has no default app.
///
/// `FirebaseRemoteConfig.instance` throws `[core/no-app]` if it runs before
/// `Firebase.initializeApp`. Call this only after startup init has returned
/// true, and still re-check [firebaseAppsReady] so a timed-out init cannot
/// reach the plugin.
RemoteConfigClient? remoteConfigClientIfReady({required bool firebaseReady}) {
  if (!firebaseReady || !firebaseAppsReady()) return null;
  return FirebaseRemoteConfigGateway(FirebaseRemoteConfig.instance);
}

class FirebaseRemoteConfigGateway implements RemoteConfigClient {
  FirebaseRemoteConfigGateway(this._remote);

  final FirebaseRemoteConfig _remote;

  @override
  Future<void> setDefaults(Map<String, Object> defaults) {
    return _remote.setDefaults(defaults);
  }

  @override
  Future<void> setSettings({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) {
    return _remote.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: minimumFetchInterval,
      ),
    );
  }

  @override
  Future<void> activate() {
    return _remote.activate();
  }

  @override
  Future<bool> fetchAndActivate() => _remote.fetchAndActivate();

  @override
  bool getBool(String key) => _remote.getBool(key);

  @override
  int getInt(String key) => _remote.getInt(key);

  @override
  String getString(String key) => _remote.getString(key);
}
