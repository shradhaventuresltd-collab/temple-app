/// Hosted Terms and Privacy documents, and the version the app requires.
///
/// Bump [currentVersion] when those documents change. A device that stored an
/// older version sees the policy-update gate again (KAN-93). Acceptance stays
/// on the device; nothing here is written to Firestore.
abstract final class PolicyConfig {
  /// Monotonic policy version. First shipped documents are version 1.
  static const int currentVersion = 1;

  static const String termsOfServiceUrl =
      'https://shradhaventuresltd-collab.github.io/temple-app/terms-of-service.html';

  static const String privacyPolicyUrl =
      'https://shradhaventuresltd-collab.github.io/temple-app/privacy-policy.html';

  static Uri get termsOfServiceUri => Uri.parse(termsOfServiceUrl);

  static Uri get privacyPolicyUri => Uri.parse(privacyPolicyUrl);
}
