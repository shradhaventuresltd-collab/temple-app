/// Sink for product analytics. Tests pass a fake. Production uses the
/// Firebase implementation only after [AppAnalytics.configure] decides
/// this process may collect.
abstract class AnalyticsClient {
  const AnalyticsClient();

  Future<void> setCollectionEnabled(bool enabled);

  /// Denies Analytics use for ads. Does not touch the ad UMP pass.
  Future<void> setConsent({
    required bool adPersonalizationSignalsConsentGranted,
    required bool adUserDataConsentGranted,
  });

  Future<void> logScreenView({required String screenName});

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });
}

/// Drops every call. The default until a production process opts in, and
/// the client unit tests use when they must not touch Firebase.
class NoopAnalyticsClient implements AnalyticsClient {
  const NoopAnalyticsClient();

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setConsent({
    required bool adPersonalizationSignalsConsentGranted,
    required bool adUserDataConsentGranted,
  }) async {}

  @override
  Future<void> logScreenView({required String screenName}) async {}

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {}
}
