import 'package:flutter/foundation.dart';

/// Compile-time define for demo builds: `--dart-define=ENABLE_ADMIN_TOOLS=true`.
/// The Play AAB is built without it (`scripts/build_play_aab.sh` refuses the define).
const bool kEnableAdminToolsDefine = bool.fromEnvironment('ENABLE_ADMIN_TOOLS');

/// `--dart-define=DEMO_BUILD=true` forces Google test ad units (KAN-89).
/// It does not enable Seed or the admin CMS. The Play script refuses it.
/// It does not change the Android application id.
const bool kDemoBuild = bool.fromEnvironment('DEMO_BUILD');

/// `--dart-define=DEMO_APP_ID_SUFFIX=true` installs the Android app as
/// `com.shradhaventures.temple.demo`. Only demo-app-distribution sets it.
/// android-smoke and demo-seed-launch do not, so they keep the Play package.
const bool kDemoAppIdSuffix = bool.fromEnvironment('DEMO_APP_ID_SUFFIX');

/// Distribution Android builds read Firebase options from the
/// google-services.json client for `com.shradhaventures.temple.demo`
/// instead of the Play app id in `firebase_options.dart`.
bool androidDemoUsesGoogleServices({
  required bool demoAppIdSuffix,
  required bool isWeb,
  required bool isAndroid,
}) => demoAppIdSuffix && !isWeb && isAndroid;

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

/// Firebase Analytics collection for the Play production binary only.
///
/// Debug and profile are off because [releaseMode] is false there, and
/// `flutter test` runs as debug. A release build is still off when it is a
/// demo (`DEMO_BUILD`), demo distribution (`DEMO_APP_ID_SUFFIX`), or a
/// seed/admin build (`ENABLE_ADMIN_TOOLS`). The Play AAB script refuses
/// those defines.
bool analyticsCollectionAllowed({
  required bool releaseMode,
  required bool demoBuild,
  required bool adminToolsDefine,
  required bool demoAppIdSuffix,
}) => releaseMode && !demoBuild && !adminToolsDefine && !demoAppIdSuffix;
