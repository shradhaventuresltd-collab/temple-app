import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:temple_app/firebase_options.dart';
import 'package:temple_app/services/ad_helper.dart';

/// Startup helpers aimed at a fast first Flutter frame (KAN-75).
///
/// Native splash is solid saffron (`#FF8F00`). Awaiting AdMob (and a slow
/// Firebase init) before [runApp] makes that orange linger for several
/// seconds even when Home would otherwise load fine.
class AppBootstrap {
  AppBootstrap._();

  /// Soft cap so a hung Firebase init cannot delay temple fetch forever.
  /// Prefer completing quickly; Home already falls back to sample temples.
  static const Duration firebaseTimeout = Duration(seconds: 4);
  static const Duration adsTimeout = Duration(seconds: 5);

  /// Initializes Firebase with a timeout. Returns `false` on failure/timeout.
  /// Call from the widget tree after [runApp] so the cream Home shell can
  /// paint immediately; do not await this in [main] before [runApp].
  static Future<bool> initializeFirebase({
    Future<void> Function()? initialize,
    Duration timeout = firebaseTimeout,
  }) async {
    try {
      final start = initialize ??
          () => Firebase.initializeApp(
                options: DefaultFirebaseOptions.currentPlatform,
              );
      await start().timeout(timeout);
      return true;
    } on TimeoutException catch (e) {
      debugPrint('Firebase.initializeApp timed out: $e');
      return false;
    } catch (e, st) {
      debugPrint('Firebase.initializeApp failed: $e\n$st');
      return false;
    }
  }

  /// Initializes AdMob without throwing. Call after the first frame only.
  static Future<void> initializeAdsSafely({
    Future<void> Function()? initialize,
    Duration timeout = adsTimeout,
  }) async {
    try {
      final start = initialize ?? AdHelper.initializeAds;
      await start().timeout(timeout);
    } on TimeoutException catch (e) {
      debugPrint('AdHelper.initializeAds timed out: $e');
    } catch (e, st) {
      debugPrint('AdHelper.initializeAds failed: $e\n$st');
    }
  }
}
