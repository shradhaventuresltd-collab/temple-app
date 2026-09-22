import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:temple_app/firebase_options.dart';
import 'package:temple_app/services/ad_consent.dart';
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

  /// Network cap for the UMP consent-info update. A timeout falls back to
  /// non-personalized ads; it does not block the first frame.
  static const Duration consentInfoTimeout = Duration(seconds: 8);

  /// Safety cap while the consent form is up. The form is user-paced and
  /// runs after the first frame. If it never returns, ads start
  /// non-personalized instead of waiting forever.
  static const Duration consentFormTimeout = Duration(minutes: 3);

  /// Cap for `MobileAds.initialize` after consent has resolved.
  static const Duration mobileAdsTimeout = Duration(seconds: 5);

  /// Backstop around the whole UMP-then-initialize future. Longer than the
  /// form cap so a visible consent form is not treated as a hung splash.
  /// [main] does not await this before [runApp].
  static const Duration adsStartupTimeout = Duration(minutes: 3, seconds: 20);

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

  /// UMP consent, then AdMob, without throwing.
  ///
  /// Call after the first frame only. A timeout or error still unblocks ad
  /// widgets with non-personalized requests so startup cannot hang.
  static Future<void> initializeAdsSafely({
    Future<void> Function()? initialize,
    Duration timeout = adsStartupTimeout,
  }) async {
    try {
      final start = initialize ??
          () => AdHelper.initializeAds(
                consentInfoTimeout: consentInfoTimeout,
                consentFormTimeout: consentFormTimeout,
                mobileAdsTimeout: mobileAdsTimeout,
              );
      await start().timeout(timeout);
    } on TimeoutException catch (e) {
      debugPrint('AdHelper.initializeAds timed out: $e');
      _unblockAdsAfterStartupFailure();
    } catch (e, st) {
      debugPrint('AdHelper.initializeAds failed: $e\n$st');
      _unblockAdsAfterStartupFailure();
    }
  }

  static void _unblockAdsAfterStartupFailure() {
    if (AdConsentController.instance.isReady) return;
    AdConsentController.instance.resolve(
      const AdConsentDecision(mode: AdConsentMode.nonPersonalized),
    );
  }
}
