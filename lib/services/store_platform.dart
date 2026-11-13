import 'package:flutter/foundation.dart';

/// Which store listing this install should open.
///
/// Tests pass a value. Production uses [currentStorePlatform], which reads
/// [defaultTargetPlatform] and does not call `Platform.isIOS`.
enum StorePlatform { android, ios }

StorePlatform currentStorePlatform({TargetPlatform? platform}) {
  if (kIsWeb) return StorePlatform.android;
  final target = platform ?? defaultTargetPlatform;
  if (target == TargetPlatform.iOS) return StorePlatform.ios;
  return StorePlatform.android;
}
