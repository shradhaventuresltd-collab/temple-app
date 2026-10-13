import 'package:flutter/foundation.dart';

/// Compile-time define for demo builds: `--dart-define=ENABLE_ADMIN_TOOLS=true`.
/// The Play AAB is built without it (`scripts/build_play_aab.sh` refuses the define).
const bool kEnableAdminToolsDefine = bool.fromEnvironment('ENABLE_ADMIN_TOOLS');

/// Pure gating rule (testable): debug builds, or any build with the define.
///
/// [kAdminToolsEnabled] is this call as a const:
/// `adminToolsEnabled(debug: kDebugMode, define: kEnableAdminToolsDefine)`.
bool adminToolsEnabled({required bool debug, required bool define}) =>
    debug || define;

/// Whether admin entry points (Seed / CMS / Upload) are compiled in.
/// Firebase sign-in + the `admin: true` custom claim are still required.
///
/// Same expression as [adminToolsEnabled]: `debug || define`.
const bool kAdminToolsEnabled = kDebugMode || kEnableAdminToolsDefine;
