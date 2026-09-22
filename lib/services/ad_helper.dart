import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:temple_app/services/ad_consent.dart';

/// AdMob unit ids and the UMP-then-initialize startup path.
///
/// iOS App Tracking Transparency (`NSUserTrackingUsageDescription` and the
/// ATT prompt) is not part of this Android release path. The iOS runner is
/// the Flutter scaffold plus an AdMob app id; ATT stays a follow-up if an
/// iOS build is actually shipped. The shared Dart UMP flow still runs on
/// iOS, and `GADDelayAppMeasurementInit` keeps measurement from starting
/// before [initializeAds].
class AdHelper {
  AdHelper._();

  static bool get isSupported => !kIsWeb;

  static bool get _mobileAdsPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Completes after UMP has resolved (including fail-soft) and
  /// `MobileAds.initialize` has been attempted.
  static Future<void> get ready => AdConsentController.instance.ready;

  static AdConsentMode get consentMode => AdConsentController.instance.mode;

  static bool get shouldRequestAds => consentAllowsAdRequest(consentMode);

  /// Consent-aware request for the current [consentMode].
  static AdRequest get adRequest => adRequestForMode(consentMode);

  /// UMP, then `MobileAds.initialize`.
  ///
  /// Call after the first Flutter frame so a consent form cannot bring back
  /// the saffron splash hang (KAN-75). Failures and timeouts still initialize
  /// ads with non-personalized requests, except when a required form was
  /// dismissed without consent — then no ad is requested.
  static Future<void> initializeAds({
    UmpClient? client,
    AdConsentController? consent,
    Future<void> Function()? initializeMobileAds,
    Duration consentInfoTimeout = const Duration(seconds: 8),
    Duration consentFormTimeout = const Duration(minutes: 3),
    Duration mobileAdsTimeout = const Duration(seconds: 5),
    ConsentRequestParameters? consentParameters,
  }) async {
    final gate = consent ?? AdConsentController.instance;
    final lateDecision = _LateConsent();
    var decision = const AdConsentDecision(mode: AdConsentMode.nonPersonalized);
    try {
      if (client == null && !_mobileAdsPlatform) {
        decision = const AdConsentDecision(mode: AdConsentMode.adsDisabled);
        return;
      }
      final ump = client ?? GoogleUmpClient();
      try {
        decision = await _collectConsent(
          ump: ump,
          gate: gate,
          lateDecision: lateDecision,
          consentInfoTimeout: consentInfoTimeout,
          consentFormTimeout: consentFormTimeout,
          params: consentParameters ?? productionConsentParameters(),
        );
      } catch (e, st) {
        debugPrint('UMP consent failed: $e\n$st');
        decision = const AdConsentDecision(mode: AdConsentMode.nonPersonalized);
      }
      try {
        final start = initializeMobileAds ?? _initializeMobileAds;
        await start().timeout(mobileAdsTimeout);
      } on TimeoutException catch (e) {
        debugPrint('MobileAds.initialize timed out: $e');
      } catch (e, st) {
        debugPrint('MobileAds.initialize failed: $e\n$st');
      }
    } finally {
      // A form that finishes during MobileAds.initialize wins over the
      // timeout fallback. Ad widgets stay blocked until this resolve.
      gate.resolve(lateDecision.value ?? decision);
    }
  }

  /// Re-reads UMP after the user opens the privacy-options form.
  ///
  /// No-op until UMP reports that a privacy-options entry point is required.
  static Future<void> presentPrivacyOptions({
    UmpClient? client,
    AdConsentController? consent,
  }) async {
    final gate = consent ?? AdConsentController.instance;
    if (!gate.privacyOptionsRequired) return;
    final ump = client ?? GoogleUmpClient();
    try {
      final error = await ump.showPrivacyOptionsForm();
      if (error != null) {
        debugPrint(
          'UMP privacy options: ${error.errorCode}: ${error.message}',
        );
      }
      gate.resolve(await _decisionFromClient(ump));
    } catch (e, st) {
      debugPrint('UMP privacy options failed: $e\n$st');
    }
  }

  static Future<AdConsentDecision> _collectConsent({
    required UmpClient ump,
    required AdConsentController gate,
    required _LateConsent lateDecision,
    required Duration consentInfoTimeout,
    required Duration consentFormTimeout,
    required ConsentRequestParameters params,
  }) async {
    try {
      await ump.requestConsentInfoUpdate(params).timeout(consentInfoTimeout);
    } on TimeoutException catch (e) {
      debugPrint('UMP consent info update timed out: $e');
      return const AdConsentDecision(mode: AdConsentMode.nonPersonalized);
    } catch (e, st) {
      debugPrint('UMP consent info update failed: $e\n$st');
      return const AdConsentDecision(mode: AdConsentMode.nonPersonalized);
    }

    final formFuture = ump.showConsentFormIfRequired();
    try {
      final formError = await formFuture.timeout(consentFormTimeout);
      if (formError != null) {
        debugPrint(
          'UMP consent form: ${formError.errorCode}: ${formError.message}',
        );
      }
    } on TimeoutException catch (e) {
      debugPrint(
        'UMP consent form timed out; continuing with non-personalized ads: $e',
      );
      unawaited(
        formFuture.then((_) async {
          try {
            final decided = await _decisionFromClient(ump);
            lateDecision.value = decided;
            // Startup has already opened the gate. Refresh later loads.
            if (gate.isReady) gate.resolve(decided);
          } catch (lateError, lateStack) {
            debugPrint(
              'UMP late consent read failed: $lateError\n$lateStack',
            );
          }
        }),
      );
      return const AdConsentDecision(mode: AdConsentMode.nonPersonalized);
    } catch (e, st) {
      debugPrint('UMP consent form failed: $e\n$st');
      return const AdConsentDecision(mode: AdConsentMode.nonPersonalized);
    }

    try {
      return await _decisionFromClient(ump);
    } catch (e, st) {
      debugPrint('UMP consent status read failed: $e\n$st');
      return const AdConsentDecision(mode: AdConsentMode.nonPersonalized);
    }
  }

  static Future<AdConsentDecision> _decisionFromClient(UmpClient ump) async {
    final status = await ump.consentStatus();
    final canRequest = await ump.canRequestAds();
    final privacyOptionsRequired = await ump.privacyOptionsRequired();
    return decideAdConsent(
      consentInfoUpdated: true,
      status: status,
      canRequestAds: canRequest,
      privacyOptionsRequired: privacyOptionsRequired,
    );
  }

  static Future<void> _initializeMobileAds() {
    return MobileAds.instance.initialize();
  }

  /// Release builds ignore debug geography dart-defines.
  static ConsentRequestParameters productionConsentParameters() {
    const geography = String.fromEnvironment('UMP_DEBUG_GEOGRAPHY');
    const testDeviceId = String.fromEnvironment('UMP_TEST_DEVICE_ID');
    final params = buildConsentRequestParameters(
      releaseMode: kReleaseMode,
      debugGeography: geography,
      testDeviceId: testDeviceId,
    );
    if (!kReleaseMode && params.consentDebugSettings != null) {
      debugPrint(
        'UMP debug geography=$geography testDevice=${testDeviceId.isEmpty ? '(none)' : 'set'}',
      );
    }
    return params;
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

/// Google UMP via `google_mobile_ads` 5.3.x.
///
/// The Android SDK already depends on
/// `com.google.android.ump:user-messaging-platform:3.1.0`. No second UMP
/// package is added.
class GoogleUmpClient implements UmpClient {
  @override
  Future<void> requestConsentInfoUpdate(ConsentRequestParameters params) {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        if (!completer.isCompleted) {
          completer.completeError(UmpRequestException(error));
        }
      },
    );
    return completer.future;
  }

  @override
  Future<FormError?> showConsentFormIfRequired() async {
    FormError? error;
    await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
      error = formError;
    });
    return error;
  }

  @override
  Future<FormError?> showPrivacyOptionsForm() async {
    FormError? error;
    await ConsentForm.showPrivacyOptionsForm((formError) {
      error = formError;
    });
    return error;
  }

  @override
  Future<ConsentStatus> consentStatus() {
    return ConsentInformation.instance.getConsentStatus();
  }

  @override
  Future<bool> canRequestAds() {
    return ConsentInformation.instance.canRequestAds();
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }
}

class _LateConsent {
  AdConsentDecision? value;
}

class UmpRequestException implements Exception {
  UmpRequestException(this.error);

  final FormError error;

  @override
  String toString() =>
      'UMP consent info update failed (${error.errorCode}): ${error.message}';
}
