import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/config/build_flags.dart';

void main() {
  group('adminToolsEnabled', () {
    test('debug build enables admin tools', () {
      expect(adminToolsEnabled(debug: true, define: false), isTrue);
    });
    test('release/profile without ENABLE_ADMIN_TOOLS hides Seed/Admin', () {
      expect(adminToolsEnabled(debug: false, define: false), isFalse);
    });
    test('demo build with ENABLE_ADMIN_TOOLS shows Seed/Admin', () {
      expect(adminToolsEnabled(debug: false, define: true), isTrue);
    });
  });

  test('kAdminToolsEnabled uses the same gate as adminToolsEnabled', () {
    expect(
      kAdminToolsEnabled,
      adminToolsEnabled(debug: kDebugMode, define: kEnableAdminToolsDefine),
    );
  });

  group('androidDemoUsesGoogleServices', () {
    test('distribution Android reads the .demo google-services client', () {
      expect(
        androidDemoUsesGoogleServices(
          demoAppIdSuffix: true,
          isWeb: false,
          isAndroid: true,
        ),
        isTrue,
      );
    });
    test('DEMO_BUILD without the suffix keeps firebase_options.dart', () {
      expect(
        androidDemoUsesGoogleServices(
          demoAppIdSuffix: false,
          isWeb: false,
          isAndroid: true,
        ),
        isFalse,
      );
    });
    test('suffix on web and non-Android keeps firebase_options.dart', () {
      expect(
        androidDemoUsesGoogleServices(
          demoAppIdSuffix: true,
          isWeb: true,
          isAndroid: true,
        ),
        isFalse,
      );
      expect(
        androidDemoUsesGoogleServices(
          demoAppIdSuffix: true,
          isWeb: false,
          isAndroid: false,
        ),
        isFalse,
      );
    });
  });

  group('analyticsCollectionAllowed', () {
    test('Play release collects', () {
      expect(
        analyticsCollectionAllowed(
          releaseMode: true,
          demoBuild: false,
          adminToolsDefine: false,
          demoAppIdSuffix: false,
        ),
        isTrue,
      );
    });

    test('debug, profile, and flutter test do not collect', () {
      expect(
        analyticsCollectionAllowed(
          releaseMode: false,
          demoBuild: false,
          adminToolsDefine: false,
          demoAppIdSuffix: false,
        ),
        isFalse,
      );
    });

    test('demo, demo suffix, and seed/admin release builds do not collect', () {
      for (final flags in [
        (demo: true, admin: false, suffix: false),
        (demo: false, admin: true, suffix: false),
        (demo: false, admin: false, suffix: true),
      ]) {
        expect(
          analyticsCollectionAllowed(
            releaseMode: true,
            demoBuild: flags.demo,
            adminToolsDefine: flags.admin,
            demoAppIdSuffix: flags.suffix,
          ),
          isFalse,
          reason: '$flags',
        );
      }
    });
  });

  test('ENABLE_ADMIN_TOOLS define is read from --dart-define', () {
    // Must be const: fromEnvironment only reads the define in a const context.
    // Passes without the flag (false) and with
    // `flutter test --dart-define=ENABLE_ADMIN_TOOLS=true` (true).
    const fromEnv = bool.fromEnvironment('ENABLE_ADMIN_TOOLS');
    expect(kEnableAdminToolsDefine, fromEnv);
  });
}
