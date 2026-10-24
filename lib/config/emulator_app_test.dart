import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/services/app_config.dart';

/// `--dart-define=EMULATOR_APP_TEST=true`.
///
/// Debug builds already have the hooks because [kDebugMode] is true there.
/// A release build that sets this define fails while evaluating
/// [kEmulatorAppTestReleaseGuard]. `scripts/build_play_aab.sh` refuses the
/// name before Gradle runs.
const bool kEmulatorAppTestDefine = bool.fromEnvironment('EMULATOR_APP_TEST');

/// Fails a release compile when [kEmulatorAppTestDefine] is true.
class _ReleaseBuildForbidsEmulatorAppTest {
  const _ReleaseBuildForbidsEmulatorAppTest()
    : assert(
        !kReleaseMode || !kEmulatorAppTestDefine,
        'EMULATOR_APP_TEST must not be set for a release build',
      );
}

/// Part of [kEmulatorAppTestHooks], so every release compile evaluates it.
const Object kEmulatorAppTestReleaseGuard =
    _ReleaseBuildForbidsEmulatorAppTest();

/// True in debug, or in any build compiled with [kEmulatorAppTestDefine].
///
/// Release without the define is a constant false, so the startup block that
/// reads the force-update preference is not in the Play binary.
/// [identical] is always false. It keeps [kEmulatorAppTestReleaseGuard] in
/// the compile so a release build with the define stops here.
const bool kEmulatorAppTestHooks =
    kDebugMode ||
    kEmulatorAppTestDefine ||
    identical(kEmulatorAppTestReleaseGuard, true);

/// Shared-preferences key. The Android XML name is `flutter.` plus this key.
///
/// The emulator checklist writes that XML with `run-as`. Nothing here is a
/// Firestore field, and nothing writes Remote Config.
const String kEmulatorForceUpdatePrefKey = 'emulator_force_update';

/// `min_supported_build` stand-in used only when the preference is set.
const int kEmulatorForceUpdateMinBuild = 1000000;

/// Installed build passed with the override.
/// Below [kEmulatorForceUpdateMinBuild].
///
/// A missing package-info read fails open and would skip the update screen.
const int kEmulatorForceUpdateInstalledBuild = 1;

/// Same rule as [kEmulatorAppTestHooks], with explicit inputs for tests.
bool emulatorAppTestHooksEnabled({
  required bool debugMode,
  required bool define,
}) => debugMode || define;

/// Local config that blocks this install on the force-update screen.
///
/// Returns null when [requested] is false. The caller skips Remote Config
/// entirely when this is non-null, so the console template is not fetched
/// and is never written.
AppConfig? emulatorForceUpdateConfig({required bool requested}) {
  if (!requested) return null;
  return const AppConfig(
    minSupportedBuild: kEmulatorForceUpdateMinBuild,
    recommendedBuild: kEmulatorForceUpdateMinBuild,
  );
}

/// Reads [kEmulatorForceUpdatePrefKey]. A plugin failure leaves startup alone.
///
/// Call only when [kEmulatorAppTestHooks] is true.
Future<AppConfig?> readEmulatorForceUpdateOverride() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final requested = prefs.getBool(kEmulatorForceUpdatePrefKey) ?? false;
    return emulatorForceUpdateConfig(requested: requested);
  } catch (e, st) {
    debugPrint('Emulator force-update hook skipped: $e\n$st');
    return null;
  }
}
