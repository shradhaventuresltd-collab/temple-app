/// Hosted Terms and Privacy documents, and the version the app requires.
///
/// Bump [currentVersion] when those documents change. A device that stored an
/// older version sees the policy-update gate again (KAN-93). Acceptance stays
/// on the device; nothing here is written to Firestore.
abstract final class PolicyConfig {
  /// Monotonic policy version. First shipped documents are version 1.
  /// Version 2 is the 23 October 2026 Temples near me update (KAN-184).
  /// Temples near me uses your device's approximate location only on your device, to sort temples by distance. That reading is never stored or sent off your device. Separately, the Google Mobile Ads SDK in this app may collect approximate location derived from your IP address, and share it with Google, for advertising, analytics and fraud prevention.
  /// A device that stored version 1 sees the update gate again.
  static const int currentVersion = 2;

  static const String termsOfServiceUrl =
      'https://temple-directory-india.web.app/terms-of-service.html';

  static const String privacyPolicyUrl =
      'https://temple-directory-india.web.app/privacy-policy.html';

  static Uri get termsOfServiceUri => Uri.parse(termsOfServiceUrl);

  static Uri get privacyPolicyUri => Uri.parse(privacyPolicyUrl);
}
