import 'package:flutter/material.dart';

/// Stable screen names. Route arguments for a temple are the temple id
/// string only.
abstract final class AnalyticsScreens {
  static const home = 'home';
  static const policyGate = 'policy_gate';
  static const forceUpdate = 'force_update';
  static const maintenance = 'maintenance';
  static const templeList = 'temple_list';
  static const templeDetail = 'temple_detail';
  static const templesNearMe = 'temples_near_me';
  static const licences = 'licences';
  static const admin = 'admin';
  static const adminTempleForm = 'admin_temple_form';

  static const allowed = <String>{
    home,
    policyGate,
    forceUpdate,
    maintenance,
    templeList,
    templeDetail,
    templesNearMe,
    licences,
    admin,
    adminTempleForm,
  };
}

/// Full-screen route with a [AnalyticsScreens] name.
MaterialPageRoute<T> namedAnalyticsRoute<T>({
  required String name,
  required WidgetBuilder builder,
  Object? arguments,
}) {
  return MaterialPageRoute<T>(
    settings: RouteSettings(name: name, arguments: arguments),
    builder: builder,
  );
}
