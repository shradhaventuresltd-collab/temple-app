import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/config/build_flags.dart';

void main() {
  group('adminToolsEnabled', () {
    test('debug build enables admin tools', () {
      expect(adminToolsEnabled(isDebug: true, defineSet: false), isTrue);
    });
    test('release/profile without ENABLE_ADMIN_TOOLS hides Seed/Admin', () {
      expect(adminToolsEnabled(isDebug: false, defineSet: false), isFalse);
    });
    test('demo build with ENABLE_ADMIN_TOOLS shows Seed/Admin', () {
      expect(adminToolsEnabled(isDebug: false, defineSet: true), isTrue);
    });
  });

  test('define is off by default (tests run without --dart-define)', () {
    expect(kEnableAdminToolsDefine, isFalse);
  });
}
