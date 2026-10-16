import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:temple_app/config/build_flags.dart';
import 'package:temple_app/firebase_options.dart';
import 'package:temple_app/services/ad_consent.dart';
import 'package:temple_app/services/ad_helper.dart';
import 'package:temple_app/services/client_cache.dart';
import 'package:temple_app/services/firebase_ready.dart';

/// Options passed to [Firebase.initializeApp] for this process.
///
/// Demo distribution (`DEMO_APP_ID_SUFFIX` on Android) returns null so the
/// native SDK reads the `.demo` client from google-services.json. Play, smoke,
/// and demo-seed pass [configured] (`DefaultFirebaseOptions`).
FirebaseOptions? startupFirebaseOptions({
  required bool demoAppIdSuffix,
  required bool isWeb,
  required bool isAndroid,
  required FirebaseOptions configured,
}) {
  if (androidDemoUsesGoogleServices(
    demoAppIdSuffix: demoAppIdSuffix,
    isWeb: isWeb,
    isAndroid: isAndroid,
  )) {
    return null;
  }
  return configured;
}

/// Startup helpers aimed at a fast first Flutter frame (KAN-75).
///
/// Native splash is solid saffron (`#FF8F00`). [main] awaits Firebase, with
/// [firebaseTimeout], before [runApp] so Auth and Firestore are not touched
/// on a missing app. Ads still start only after Terms, and they do not block
/// that first frame.
class AppBootstrap {
  AppBootstrap._();

  /// Soft cap so a hung Firebase init cannot delay temple fetch forever.
  /// Prefer completing quickly. Home then serves the saved list or an error.
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
  ///
  /// [main] awaits this before [runApp] on every flavour, including demo
  /// distribution (`DEMO_APP_ID_SUFFIX`, options from google-services.json)
  /// and demo-seed (options from [DefaultFirebaseOptions]). A failure still
  /// returns and the app paints from cache, or shows an error with Retry.
  ///
  /// On success, Firestore settings are applied before this future
  /// completes. Persistence and the 100 MiB cache are in place before the
  /// first query. A settings failure is logged and still counts Firebase
  /// as ready, so a later directory read can use the cache.
  static Future<bool> initializeFirebase({
    Future<void> Function()? initialize,
    void Function()? configureFirestore,
    Duration timeout = firebaseTimeout,
  }) async {
    try {
      if (initialize == null && firebaseAppsReady()) {
        // A process that already called initializeApp may still be missing
        // persistence settings. Applying them twice throws; that is logged
        // below and does not fail startup.
        try {
          final configure = configureFirestore ?? _configureLiveFirestore;
          configure();
        } catch (e, st) {
          debugPrint('Firestore settings failed: $e\n$st');
        }
        return true;
      }
      final start =
          initialize ??
          () => Firebase.initializeApp(
            options: startupFirebaseOptions(
              demoAppIdSuffix: kDemoAppIdSuffix,
              isWeb: kIsWeb,
              isAndroid:
                  !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
              configured: DefaultFirebaseOptions.currentPlatform,
            ),
          );
      await start().timeout(timeout);
    } on TimeoutException catch (e) {
      debugPrint('Firebase.initializeApp timed out: $e');
      return false;
    } catch (e, st) {
      debugPrint('Firebase.initializeApp failed: $e\n$st');
      return false;
    }
    try {
      final configure =
          configureFirestore ??
          (initialize == null ? _configureLiveFirestore : null);
      configure?.call();
    } catch (e, st) {
      debugPrint('Firestore settings failed: $e\n$st');
    }
    return true;
  }

  static void _configureLiveFirestore() {
    configureDirectoryFirestore(FirebaseFirestore.instance);
  }

  /// UMP consent, then AdMob, without throwing.
  ///
  /// Call only after Terms and Privacy have been accepted (KAN-93). Do not
  /// await this before Home: a slow UMP pass brought back the startup hang
  /// (KAN-75). Ad widgets stay blocked until this resolves. A timeout or error
  /// still unblocks them with non-personalized requests.
  static Future<void> initializeAdsSafely({
    Future<void> Function()? initialize,
    Duration timeout = adsStartupTimeout,
  }) async {
    try {
      final start =
          initialize ??
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
