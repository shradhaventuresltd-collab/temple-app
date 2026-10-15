import 'package:flutter/foundation.dart';

/// Compile-time define for demo builds: `--dart-define=ENABLE_ADMIN_TOOLS=true`.
/// The Play AAB is built without it (`scripts/build_play_aab.sh` refuses the define).
const bool kEnableAdminToolsDefine = bool.fromEnvironment('ENABLE_ADMIN_TOOLS');

/// `--dart-define=DEMO_BUILD=true` forces Google test ad units (KAN-89).
/// It does not enable Seed or the admin CMS. The Play script refuses it.
/// On Android it also selects the `.demo` application id.
const bool kDemoBuild = bool.fromEnvironment('DEMO_BUILD');

/// Demo Android builds read Firebase options from the google-services.json
/// client for `com.shradhaventures.temple.demo` instead of the Play app id
/// in `firebase_options.dart`.
bool androidDemoUsesGoogleServices({
  required bool demoBuild,
  required bool isWeb,
  required bool isAndroid,
}) =>
    demoBuild && !isWeb && isAndroid;

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
