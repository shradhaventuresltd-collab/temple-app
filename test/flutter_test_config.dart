import 'dart:async';

import 'package:temple_app/district/district_lookup.dart';

/// Widget tests pump the drawer and the list often. Leave district warm-up
/// off unless a test turns it on. Production and the emulator keep the
/// default.
Future<void> testExecutable(Future<void> Function() testMain) async {
  debugWarmDirectoryDistricts = false;
  await testMain();
}
