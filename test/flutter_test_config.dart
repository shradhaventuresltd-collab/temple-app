import 'dart:async';

import 'package:temple_app/district/district_lookup.dart';
import 'package:temple_app/services/review_prompt.dart';

/// Widget tests pump the drawer and the list often. Leave district warm-up
/// off unless a test turns it on. Production and the emulator keep the
/// default.
Future<void> testExecutable(Future<void> Function() testMain) async {
  debugWarmDirectoryDistricts = false;
  // No Play review channel or shared preferences writes from unrelated
  // widget tests. Review tests inject their own prompter.
  ReviewPrompter.instance = ReviewPrompter.disabled();
  await testMain();
}
