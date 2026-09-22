import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// How ad requests should behave after one UMP pass.
///
/// Personalized requests are used only when UMP says consent is not required.
/// After the user completes a form, requests do not force `npa`; the Google
/// Mobile Ads SDK applies the TCF string UMP stored. Failures fall back to
/// non-personalized requests. A required form that was dismissed without
/// consent does not request ads.
enum AdConsentMode {
  /// Consent has not finished. Do not request ads yet.
  pending,

  /// UMP geography does not require a consent form (typical for India).
  personalized,

  /// The user finished the UMP form. Do not force non-personalized ads.
  umpHonored,

  /// UMP failed, timed out, or status stayed unknown while ads may load.
  nonPersonalized,

  /// A form is required and consent was not obtained. Do not request ads.
  adsDisabled,
}

/// Result of reading UMP after an update (or a fail-soft fallback).
class AdConsentDecision {
  const AdConsentDecision({
    required this.mode,
    this.privacyOptionsRequired = false,
  });

  final AdConsentMode mode;
  final bool privacyOptionsRequired;
}

/// Maps a UMP snapshot to an ad-request policy.
///
/// [consentInfoUpdated] is false when the consent-info call failed or timed
/// out. In that case the app still runs and ads are non-personalized.
AdConsentDecision decideAdConsent({
  required bool consentInfoUpdated,
  ConsentStatus? status,
  bool? canRequestAds,
  bool privacyOptionsRequired = false,
}) {
  if (!consentInfoUpdated || status == null || canRequestAds == null) {
    return const AdConsentDecision(mode: AdConsentMode.nonPersonalized);
  }
  if (status == ConsentStatus.required || !canRequestAds) {
    return AdConsentDecision(
      mode: AdConsentMode.adsDisabled,
      privacyOptionsRequired: privacyOptionsRequired,
    );
  }
  switch (status) {
    case ConsentStatus.notRequired:
      return AdConsentDecision(
        mode: AdConsentMode.personalized,
        privacyOptionsRequired: privacyOptionsRequired,
      );
    case ConsentStatus.obtained:
      return AdConsentDecision(
        mode: AdConsentMode.umpHonored,
        privacyOptionsRequired: privacyOptionsRequired,
      );
    case ConsentStatus.unknown:
    case ConsentStatus.required:
      return AdConsentDecision(
        mode: AdConsentMode.nonPersonalized,
        privacyOptionsRequired: privacyOptionsRequired,
      );
  }
}

/// True when a banner or interstitial may call `load`.
bool consentAllowsAdRequest(AdConsentMode mode) {
  switch (mode) {
    case AdConsentMode.personalized:
    case AdConsentMode.umpHonored:
    case AdConsentMode.nonPersonalized:
      return true;
    case AdConsentMode.pending:
    case AdConsentMode.adsDisabled:
      return false;
  }
}

/// Consent-aware [AdRequest].
///
/// `nonPersonalizedAds: true` is the plugin's `npa=1` flag. It is set for the
/// fail-soft path only. [AdConsentMode.umpHonored] leaves the flag unset so
/// the Mobile Ads SDK can honor the UMP form (accept personalized ads, or
/// restrict them from the stored TCF string).
AdRequest adRequestForMode(AdConsentMode mode) {
  switch (mode) {
    case AdConsentMode.nonPersonalized:
    case AdConsentMode.pending:
    case AdConsentMode.adsDisabled:
      return const AdRequest(nonPersonalizedAds: true);
    case AdConsentMode.personalized:
    case AdConsentMode.umpHonored:
      return const AdRequest();
  }
}

/// Debug geography for `flutter run --dart-define=UMP_DEBUG_GEOGRAPHY=EEA`.
///
/// Ignored in release. UMP only applies [ConsentDebugSettings] on devices
/// listed in [testDeviceId] (the hashed id logcat prints on the first
/// consent request).
ConsentRequestParameters buildConsentRequestParameters({
  required bool releaseMode,
  String debugGeography = '',
  String testDeviceId = '',
}) {
  if (releaseMode) {
    return ConsentRequestParameters();
  }
  final geography = debugGeographyFromName(debugGeography);
  final device = testDeviceId.trim();
  if (geography == null && device.isEmpty) {
    return ConsentRequestParameters();
  }
  return ConsentRequestParameters(
    consentDebugSettings: ConsentDebugSettings(
      debugGeography: geography,
      testIdentifiers: device.isEmpty ? null : <String>[device],
    ),
  );
}

/// Accepts `EEA`, `US` / `REGULATED_US_STATE`, and `OTHER`.
DebugGeography? debugGeographyFromName(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'EEA':
      return DebugGeography.debugGeographyEea;
    case 'US':
    case 'REGULATED_US_STATE':
      return DebugGeography.debugGeographyRegulatedUsState;
    case 'OTHER':
      return DebugGeography.debugGeographyOther;
    default:
      return null;
  }
}

/// Platform UMP calls. Tests pass a fake; production uses Google's SDK.
abstract class UmpClient {
  Future<void> requestConsentInfoUpdate(ConsentRequestParameters params);

  /// Loads and shows a form only when UMP says one is required.
  ///
  /// Completes with a [FormError] when the form fails, or null when the user
  /// dismisses it or no form was required.
  Future<FormError?> showConsentFormIfRequired();

  Future<FormError?> showPrivacyOptionsForm();

  Future<ConsentStatus> consentStatus();

  Future<bool> canRequestAds();

  Future<bool> privacyOptionsRequired();
}

/// In-memory consent gate. Ad widgets wait on [ready] before loading.
class AdConsentController extends ChangeNotifier {
  /// Process-wide gate used by startup and ad widgets.
  static final AdConsentController instance = AdConsentController();

  AdConsentMode mode = AdConsentMode.pending;
  bool privacyOptionsRequired = false;
  bool _resolved = false;
  Completer<void> _pending = Completer<void>();

  bool get isReady => _resolved;

  /// Completes after the first [resolve] (consent outcome, including fallback).
  ///
  /// A later [resetForTest] returns a new future from this getter.
  Future<void> get ready => _pending.future;

  void resolve(AdConsentDecision decision) {
    mode = decision.mode;
    privacyOptionsRequired = decision.privacyOptionsRequired;
    if (!_resolved) {
      _resolved = true;
      if (!_pending.isCompleted) {
        _pending.complete();
      }
    }
    notifyListeners();
  }

  /// Drops the current decision so a test can run startup again.
  ///
  /// Waiters that already hold [ready] are released. The next read of [ready]
  /// blocks until [resolve].
  void resetForTest() {
    mode = AdConsentMode.pending;
    privacyOptionsRequired = false;
    _resolved = false;
    if (!_pending.isCompleted) {
      _pending.complete();
    }
    _pending = Completer<void>();
    notifyListeners();
  }
}
