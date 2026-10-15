import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Home listens and refreshes the directory without blanking the list.
class DirectoryReconnect {
  DirectoryReconnect._();

  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  static void notify() {
    tick.value = tick.value + 1;
  }
}

/// Connectivity for the offline banner. Hidden until a check says offline,
/// so a missing plugin does not cover the first frame.
class DirectoryLink {
  DirectoryLink._();

  static final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  static StreamSubscription<bool>? _subscription;
  static Timer? _reconnectTimer;
  static var _wasOffline = false;

  /// Wait after the network returns before refreshing the directory, so a
  /// flapping link does not reload on every blip.
  static const Duration reconnectDelay = Duration(seconds: 5);

  static void listen(Stream<bool> online) {
    _subscription?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _wasOffline = false;
    offline.value = false;
    _subscription = online.listen(
      _apply,
      onError: (Object error, StackTrace stack) {
        debugPrint('Connectivity watch failed: $error\n$stack');
      },
    );
  }

  static void _apply(bool online) {
    if (!online) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _wasOffline = true;
      offline.value = true;
      return;
    }
    final reconnect = _wasOffline;
    _wasOffline = false;
    offline.value = false;
    if (!reconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      _reconnectTimer = null;
      DirectoryReconnect.notify();
    });
  }

  /// Drops the watch. Tests call this so a later case starts from online.
  static void resetForTest() {
    _subscription?.cancel();
    _subscription = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _wasOffline = false;
    offline.value = false;
  }
}

/// A device with no listed transport is offline. `none` alone is offline.
bool connectivityIsOnline(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((result) => result != ConnectivityResult.none);
}

/// Current status, then changes. A failed check stays online so the banner
/// does not flash over the first frame.
Stream<bool> directoryConnectivity({Connectivity? connectivity}) async* {
  final link = connectivity ?? Connectivity();
  try {
    yield connectivityIsOnline(await link.checkConnectivity());
  } catch (error, stack) {
    debugPrint('Connectivity check failed: $error\n$stack');
    yield true;
  }
  yield* link.onConnectivityChanged.map(connectivityIsOnline);
}
