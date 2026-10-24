import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:temple_app/config/build_flags.dart';
import 'package:temple_app/services/analytics_client.dart';
import 'package:temple_app/services/analytics_routes.dart';
import 'package:temple_app/services/product_analytics_client.dart';

/// GA4 string parameters are capped at 100 characters.
const int _maxParameterLength = 100;

const _filterTypes = {'state', 'deity', 'district'};

/// Product analytics. The ad consent pass is not called from here and is
/// not changed (KAN-69).
///
/// [configure] runs after Firebase init. Collection stays off unless
/// [analyticsCollectionAllowed] is true. Debug, profile, demo, seed/admin,
/// and test builds keep the no-op client, so unit tests never construct
/// the Firebase SDK.
class AppAnalytics {
  AppAnalytics({AnalyticsClient? client, this.collectionEnabled = false})
    : client = client ?? const NoopAnalyticsClient();

  final AnalyticsClient client;
  final bool collectionEnabled;

  static AppAnalytics instance = AppAnalytics();

  /// Test hook. Production does not call this.
  static void resetForTest([AppAnalytics? replacement]) {
    instance = replacement ?? AppAnalytics();
  }

  /// Applies the native collection flag, then keeps a live client only when
  /// this process may collect.
  ///
  /// [firebaseClient] is for tests. Production uses the Firebase SDK, and
  /// only when [firebaseReady] is true.
  static Future<void> configure({
    required bool firebaseReady,
    required bool releaseMode,
    required bool demoBuild,
    required bool adminToolsDefine,
    required bool demoAppIdSuffix,
    AnalyticsClient Function()? firebaseClient,
  }) async {
    final allowed = analyticsCollectionAllowed(
      releaseMode: releaseMode,
      demoBuild: demoBuild,
      adminToolsDefine: adminToolsDefine,
      demoAppIdSuffix: demoAppIdSuffix,
    );
    if (!firebaseReady) {
      instance = AppAnalytics(collectionEnabled: false);
      return;
    }
    final client = firebaseClient != null
        ? firebaseClient()
        : ProductAnalyticsClient.live();
    var enabled = false;
    try {
      await client
          .setCollectionEnabled(allowed)
          .timeout(const Duration(seconds: 2));
      enabled = allowed;
    } catch (e, st) {
      debugPrint('Analytics collection flag failed: $e\n$st');
    }
    instance = AppAnalytics(
      client: enabled ? client : const NoopAnalyticsClient(),
      collectionEnabled: enabled,
    );
  }

  Future<void> logScreenView(String screenName) {
    if (!AnalyticsScreens.allowed.contains(screenName)) {
      return Future<void>.value();
    }
    return _guard(() => client.logScreenView(screenName: screenName));
  }

  /// Search. [queryLength] is the trimmed query length. The query text is
  /// not a parameter.
  Future<void> logSearch({required int queryLength, required bool hasResults}) {
    if (queryLength <= 0) return Future<void>.value();
    return _guard(
      () => client.logEvent(
        name: 'search',
        parameters: {
          'query_length': queryLength,
          'has_results': hasResults ? 1 : 0,
        },
      ),
    );
  }

  Future<void> logFilterUsed({required String type, required String value}) {
    if (!_filterTypes.contains(type)) return Future<void>.value();
    final name = _clip(value);
    if (name.isEmpty) return Future<void>.value();
    return _guard(
      () => client.logEvent(
        name: 'filter_used',
        parameters: {'type': type, 'value': name},
      ),
    );
  }

  /// Logs one event for each filter that changed to a non-empty name.
  /// Clearing a filter does not log.
  Future<void> logFilterTransition({
    required String? previousState,
    required String? nextState,
    required String? previousDeity,
    required String? nextDeity,
    required String? previousDistrict,
    required String? nextDistrict,
  }) async {
    await _logFilterDelta('state', previousState, nextState);
    await _logFilterDelta('deity', previousDeity, nextDeity);
    await _logFilterDelta('district', previousDistrict, nextDistrict);
  }

  Future<void> logTempleOpened(String templeId) {
    return _logTemple('temple_opened', templeId);
  }

  Future<void> logGetDirections(String templeId) {
    return _logTemple('get_directions', templeId);
  }

  /// Feature open. No parameters.
  Future<void> logTemplesNearMe() {
    return _guard(() => client.logEvent(name: 'temples_near_me'));
  }

  Future<void> _logFilterDelta(String type, String? previous, String? next) {
    final before = previous?.trim() ?? '';
    final after = next?.trim() ?? '';
    if (after.isEmpty || after == before) return Future<void>.value();
    return logFilterUsed(type: type, value: after);
  }

  Future<void> _logTemple(String name, String templeId) {
    final id = _clip(templeId);
    if (id.isEmpty) return Future<void>.value();
    return _guard(
      () => client.logEvent(name: name, parameters: {'temple_id': id}),
    );
  }

  Future<void> _guard(Future<void> Function() send) async {
    try {
      await send();
    } catch (e, st) {
      debugPrint('Analytics event failed: $e\n$st');
    }
  }
}

String _clip(String raw) {
  final trimmed = raw.trim();
  if (trimmed.length <= _maxParameterLength) return trimmed;
  return trimmed.substring(0, _maxParameterLength);
}
