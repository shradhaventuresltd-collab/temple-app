import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:temple_app/services/analytics_client.dart';

/// Firebase Analytics SDK wrapper. Construct only after Firebase is ready.
class ProductAnalyticsClient implements AnalyticsClient {
  ProductAnalyticsClient(this._analytics);

  factory ProductAnalyticsClient.live() {
    return ProductAnalyticsClient(FirebaseAnalytics.instance);
  }

  final FirebaseAnalytics _analytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> logScreenView({required String screenName}) {
    return _analytics.logScreenView(screenName: screenName);
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }
}
