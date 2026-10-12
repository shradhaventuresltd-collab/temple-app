import 'package:flutter/foundation.dart';

/// Compile-time define for demo builds: `--dart-define=ENABLE_ADMIN_TOOLS=true`.
/// The Play AAB is built without it, so release builds never expose admin.
const bool kEnableAdminToolsDefine = bool.fromEnvironment('ENABLE_ADMIN_TOOLS');

/// Pure gating rule (testable): debug builds, or any build with the define.
bool adminToolsEnabled({required bool isDebug, required bool defineSet}) =>
    isDebug || defineSet;

/// Whether admin entry points (Seed / CMS / Upload) are compiled in.
/// Firebase sign-in + the `admin: true` custom claim are still required.
const bool kAdminToolsEnabled = kDebugMode || kEnableAdminToolsDefine;
