import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Podfile platform matches the Xcode deployment target', () {
    final podfile = File('ios/Podfile').readAsStringSync();
    expect(podfile, contains("platform :ios, '13.0'"));
    expect(podfile, isNot(contains("# platform :ios, '13.0'")));
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(project, contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0;'));
  });

  test('analyze-test path filters include ios and stay on ubuntu', () {
    final ci = File('.github/workflows/ci.yml').readAsStringSync();
    expect(ci, contains("runs-on: ubuntu-latest"));
    expect(ci, isNot(contains('macos')));
    expect('ios/**'.allMatches(ci), hasLength(2));
  });

  test(
    'Runner bundle id is the Play id; Firebase files still match each other',
    () {
      // PRODUCT_BUNDLE_IDENTIFIER is com.shradhaventures.temple. The
      // checked-in GoogleService-Info.plist and firebase_options iosBundleId
      // stay on com.example.templeApp until Sanu re-registers the Firebase
      // iOS app. Those two files move together. Firebase may log a bundle-id
      // mismatch until then. macos/ is not part of this check.
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final ids = RegExp(
        r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);',
      ).allMatches(project).map((match) => match.group(1)!.trim()).toList();
      final runner = ids.where((id) => !id.endsWith('.RunnerTests')).toList();
      final tests = ids.where((id) => id.endsWith('.RunnerTests')).toList();
      expect(runner, [
        'com.shradhaventures.temple',
        'com.shradhaventures.temple',
        'com.shradhaventures.temple',
      ]);
      expect(tests, [
        'com.shradhaventures.temple.RunnerTests',
        'com.shradhaventures.temple.RunnerTests',
        'com.shradhaventures.temple.RunnerTests',
      ]);

      final plist = File(
        'ios/Runner/GoogleService-Info.plist',
      ).readAsStringSync();
      final plistBundle = RegExp(
        r'<key>BUNDLE_ID</key>\s*<string>([^<]+)</string>',
      ).firstMatch(plist)!.group(1)!;
      final options = File('lib/firebase_options.dart').readAsStringSync();
      final iosOptions = RegExp(
        r'static const FirebaseOptions ios = FirebaseOptions\((.*?)\);',
        dotAll: true,
      ).firstMatch(options)!.group(1)!;
      final firebaseBundle = RegExp(
        r"iosBundleId: '([^']+)'",
      ).firstMatch(iosOptions)!.group(1)!;
      expect(plistBundle, firebaseBundle);
      expect(plistBundle, 'com.example.templeApp');
      expect(runner.toSet().single, isNot(plistBundle));
    },
  );

  test('Info.plist can query the App Store and does not ask for ATT', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>LSApplicationQueriesSchemes</key>'));
    expect(plist, contains('<string>itms-apps</string>'));
    expect(plist, contains('<string>itms</string>'));
    expect(plist, isNot(contains('<key>NSUserTrackingUsageDescription</key>')));
    expect(
      plist,
      contains('https://developers.google.com/admob/ios/privacy/strategies'),
    );
    expect(plist, contains('<string>cstr6suwn9.skadnetwork</string>'));
    expect(plist, contains('<string>3qcr597p9d.skadnetwork</string>'));
    expect(
      RegExp(r'<key>SKAdNetworkIdentifier</key>').allMatches(plist),
      hasLength(50),
    );

    final swift = Directory('ios')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.swift'))
        .map((file) => file.readAsStringSync())
        .join('\n');
    expect(swift, isNot(contains('ATTrackingManager')));
    expect(swift, isNot(contains('NSUserTrackingUsageDescription')));
  });

  test('Swift Package Manager stays off so AdMob can see its webview pod', () {
    // google_mobile_ads is CocoaPods-only and depends on the
    // webview_flutter_wkwebview pod. With Swift Package Manager on, Flutter
    // omits that plugin from the Podfile and pod install cannot resolve it.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('enable-swift-package-manager: false'));
    expect(pubspec, contains('google_mobile_ads:'));
  });

  test('ios-build is manual, on macOS, and is not dispatched here', () {
    final workflow = File('.github/workflows/ios-build.yml').readAsStringSync();
    expect(
      workflow,
      contains(
        'macOS minutes bill at 10x; do not dispatch without Sanu\'s OK.',
      ),
    );
    final onBlock = RegExp(
      r'^on:\n((?:  .*\n)*)',
      multiLine: true,
    ).firstMatch(workflow)!.group(1)!;
    expect(onBlock, contains('workflow_dispatch:'));
    expect(onBlock, isNot(contains('push:')));
    expect(onBlock, isNot(contains('pull_request:')));
    expect(onBlock, isNot(contains('schedule:')));
    expect(workflow, contains('runs-on: macos-latest'));
    expect(workflow, contains('timeout-minutes: 30'));
    expect(workflow, contains("flutter-version: '3.47.7'"));
    expect(workflow, contains('flutter pub get'));
    expect(workflow, contains('flutter build ios --config-only --no-codesign'));
    expect(workflow, contains('flutter build ios --no-codesign --debug'));
    expect(workflow, contains('flutter build ios --simulator'));
  });
}
