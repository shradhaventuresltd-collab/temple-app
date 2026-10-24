import 'dart:async';

import 'package:flutter/material.dart';
import 'package:temple_app/services/analytics_routes.dart';
import 'package:temple_app/services/app_analytics.dart';

/// Screen views for named page routes.
///
/// Sheets are ignored. The navigator root (`/`) is not a product screen on
/// push; popping back to it counts as Home. Temple id is the route argument
/// when it is a string. Temples near me carries no arguments into the event.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) return;
    if (previousRoute?.settings.name == Navigator.defaultRouteName) {
      unawaited(AppAnalytics.instance.logScreenView(AnalyticsScreens.home));
      return;
    }
    _log(previousRoute);
  }

  void _log(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name;
    if (name == null || name.isEmpty || name == Navigator.defaultRouteName) {
      return;
    }
    final analytics = AppAnalytics.instance;
    unawaited(analytics.logScreenView(name));
    if (name == AnalyticsScreens.templeDetail) {
      final id = route.settings.arguments;
      if (id is String) unawaited(analytics.logTempleOpened(id));
    } else if (name == AnalyticsScreens.templesNearMe) {
      unawaited(analytics.logTemplesNearMe());
    }
  }
}
