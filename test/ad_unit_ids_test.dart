import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/ad_unit_ids.dart';

void main() {
  group('DEMO_BUILD forces Google test units', () {
    test('release + DEMO_BUILD uses Android test banner and interstitial', () {
      expect(
        bannerAdUnitIdFor(releaseMode: true, demoBuild: true, android: true),
        kGoogleTestBannerAndroid,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: true,
          demoBuild: true,
          android: true,
        ),
        kGoogleTestInterstitialAndroid,
      );
    });

    test('release + DEMO_BUILD uses iOS test units', () {
      expect(
        bannerAdUnitIdFor(releaseMode: true, demoBuild: true, android: false),
        kGoogleTestBannerIos,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: true,
          demoBuild: true,
          android: false,
        ),
        kGoogleTestInterstitialIos,
      );
    });

    test('release without DEMO_BUILD keeps production units', () {
      expect(
        bannerAdUnitIdFor(releaseMode: true, demoBuild: false, android: true),
        kProductionBannerAndroid,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: true,
          demoBuild: false,
          android: true,
        ),
        kProductionInterstitialAndroid,
      );
      expect(
        bannerAdUnitIdFor(releaseMode: true, demoBuild: false, android: false),
        kProductionBannerIos,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: true,
          demoBuild: false,
          android: false,
        ),
        kProductionInterstitialIos,
      );
    });

    test('debug and profile stay on test units without the define', () {
      expect(
        bannerAdUnitIdFor(releaseMode: false, demoBuild: false, android: true),
        kGoogleTestBannerAndroid,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: false,
          demoBuild: false,
          android: true,
        ),
        kGoogleTestInterstitialAndroid,
      );
      expect(
        bannerAdUnitIdFor(releaseMode: false, demoBuild: false, android: false),
        kGoogleTestBannerIos,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: false,
          demoBuild: false,
          android: false,
        ),
        kGoogleTestInterstitialIos,
      );
    });
  });

  group('AdMob application id', () {
    test('DEMO_BUILD selects the Google test app id', () {
      expect(admobApplicationIdFor(demoBuild: true), kGoogleTestAppId);
      expect(admobApplicationIdFor(demoBuild: false), kProductionAndroidAppId);
    });

    test('iOS xcconfig resolves Debug to the test id and Release to prod', () {
      final info = File('ios/Runner/Info.plist').readAsStringSync();
      final debug = _xcconfigValue('ios/Flutter/Debug.xcconfig', 'GAD_APP_ID');
      final release = _xcconfigValue(
        'ios/Flutter/Release.xcconfig',
        'GAD_APP_ID',
      );
      expect(info, contains(r'$(GAD_APP_ID)'));
      expect(info, isNot(contains(kGoogleTestIosAppId)));
      expect(info, isNot(contains(kProductionIosAppId)));
      expect(debug, kGoogleTestIosAppId);
      expect(release, kProductionIosAppId);
      expect(debug, isNot(release));
      final demoConfigs = Directory('ios')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.xcconfig') &&
                file.path.toLowerCase().contains('demo'),
          );
      expect(demoConfigs, isEmpty);
    });

    test('Android Gradle placeholder uses the same app ids', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains(r'${admobAppId}'));
      expect(gradle, contains(kGoogleTestAppId));
      expect(gradle, contains(kProductionAndroidAppId));
    });
  });
}

String _xcconfigValue(String path, String key) {
  final match = RegExp(
    '^$key\\s*=\\s*(\\S+)',
    multiLine: true,
  ).firstMatch(File(path).readAsStringSync());
  expect(match, isNotNull, reason: '$path has no $key');
  return match!.group(1)!;
}
