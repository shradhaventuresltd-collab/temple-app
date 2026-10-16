import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Android `versionCode` from [PackageInfo.buildNumber].
///
/// Null when the plugin fails, the read times out, or the value is not an
/// integer. Callers fail open on null so a broken read cannot block launch.
Future<int?> readInstalledBuildNumber({
  Future<String> Function()? readBuildNumber,
  Duration timeout = const Duration(seconds: 2),
}) async {
  try {
    final read = readBuildNumber ?? _platformBuildNumber;
    final raw = await read().timeout(timeout);
    return int.tryParse(raw.trim());
  } catch (e, st) {
    debugPrint('Installed build number unavailable: $e\n$st');
    return null;
  }
}

Future<String> _platformBuildNumber() async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber;
}
