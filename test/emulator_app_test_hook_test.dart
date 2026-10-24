import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/config/emulator_app_test.dart';

void main() {
  test('hooks compile in for debug or EMULATOR_APP_TEST only', () {
    expect(
      emulatorAppTestHooksEnabled(debugMode: false, define: false),
      isFalse,
    );
    expect(
      emulatorAppTestHooksEnabled(debugMode: true, define: false),
      isTrue,
    );
    expect(
      emulatorAppTestHooksEnabled(debugMode: false, define: true),
      isTrue,
    );
    expect(kEmulatorAppTestHooks, kDebugMode || kEmulatorAppTestDefine);
  });

  test('force-update override blocks locally and does not change defaults', () {
    expect(emulatorForceUpdateConfig(requested: false), isNull);

    final config = emulatorForceUpdateConfig(requested: true)!;
    expect(config.minSupportedBuild, kEmulatorForceUpdateMinBuild);
    expect(config.recommendedBuild, kEmulatorForceUpdateMinBuild);
    expect(config.minSupportedBuild, greaterThan(5));
    expect(
      kEmulatorForceUpdateInstalledBuild,
      lessThan(config.minSupportedBuild),
    );
    expect(config.killSwitch, isFalse);
    expect(config.adsEnabled, isTrue);
    expect(config.maintenanceMessage, isEmpty);
    expect(kEmulatorForceUpdatePrefKey, 'emulator_force_update');
  });
}
