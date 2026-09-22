import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  AdHelper._();

  static bool get isSupported => !kIsWeb;

  static Future<void> initializeAds() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await MobileAds.instance.initialize();
    } catch (e, st) {
      // Ads must never delay the first Home frame (KAN-75).
      debugPrint('MobileAds.initialize failed: $e\n$st');
    }
  }

  static String get bannerAdUnitId {
    assert(!kIsWeb, 'AdHelper should not be used on web');
    if (!kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-7782159535499045/8504682685'
        : 'ca-app-pub-7782159535499045/9654826832';
  }

  static String get interstitialAdUnitId {
    assert(!kIsWeb, 'AdHelper should not be used on web');
    if (!kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-7782159535499045/8118383886'
        : 'ca-app-pub-7782159535499045/1552975530';
  }
}
